# 数据包重构方案 (Data Packs Refactoring Plan)

> **状态更新 (2026-02-03):**  
> 经讨论决定采用**简化方案** - 保持现有的字母排序加载机制，只进行文件合并和命名规范化。
> **不引入** load_order.yml 配置文件。

## 📋 当前问题分析

### 1. **核心问题概述**

经过全面检查 `app/validators/support/data_packs/v1/` 目录，发现以下严重问题:

#### ❌ 问题1: 数据包之间存在依赖关系,但无法保证加载顺序
**现状:**
- `lib/tasks/validator.rake` 使用 `Dir.glob().sort` 按**文件名字母顺序**加载
- 某些数据包有明确的先后依赖关系

**具体案例:**
```ruby
# hotels_for_packages.rb (第93-94行)
existing_count = Hotel.where("brand LIKE ?", "%#{brand_name}%").where(city: city).count
# ⚠️ 依赖: 假设 hotels_all.rb 已经加载

# z_hotel_packages_associations.rb (第21行)
created_packages = HotelPackage.where(data_version: 0, hotel_id: nil)
# ⚠️ 依赖: hotel_packages.rb 和 hotels_for_packages.rb 必须已加载
```

**风险:**
- 文件重命名可能破坏加载顺序
- 新增数据包难以判断应该放在哪个位置
- 只有 `base.rb` 和 `z_` 开头的文件有明确顺序保证

---

#### ❌ 问题2: 同一业务模块数据分散在多个文件
**案例 - 酒店模块:**
```
hotels_all.rb              # 统一酒店数据 (747行)
hotels_for_packages.rb     # 套餐相关酒店 (228行)
hotels_phase2_fields_update.rb  # Phase2字段更新 (74行)
hotels_all_fix.rb          # 价格修复脚本 (20行)
z_hotel_packages_associations.rb  # 套餐关联更新 (69行)
```

**问题:**
- **维护困难**: 修改酒店数据需要检查5个文件
- **逻辑分散**: 酒店创建 → 字段更新 → 价格修复 → 关联更新,逻辑割裂
- **重复代码**: 多个文件中重复定义品牌、设施配置等

---

#### ❌ 问题3: Supplement 和 Phase2 文件职责不清
**现状文件:**
```
flights.rb (1579行)
flights_supplement.rb (173行)
flights_phase2_fields_update.rb (39行)

trains.rb (970行)  
trains_extended.rb (163行)

cars.rb (2100行)
cars_supplement.rb (134行)

bus_tickets.rb (189行)
bus_tickets_supplement.rb (81行)

tour_group_products_all.rb (531行)
tour_groups_supplement.rb (117行)

z_homestays_supplement.rb (140行)
```

**问题:**
- `_supplement` 文件含义模糊:补充数据?额外场景?修复bug?
- `_phase2_fields_update` 和 `_extended` 命名不一致
- 很难判断某个新场景应该加在主文件还是supplement文件

---

#### ❌ 问题4: 数据清理操作存在风险
**案例 1 - attractions.rb:**
```ruby
# 第13-20行
AttractionReview.destroy_all
ActivityOrder.destroy_all
TicketOrder.destroy_all
AttractionActivity.destroy_all
TicketSupplier.destroy_all
Ticket.destroy_all
Attraction.destroy_all
```

**案例 2 - hotels_all.rb:**
```ruby
# 第8-16行
HotelHighlight.destroy_all
HotelNearbyPlace.destroy_all
HotelFacility.destroy_all
HotelReview.destroy_all
HotelPolicy.destroy_all
Room.destroy_all
HotelRoom.destroy_all
Hotel.destroy_all
```

**案例 3 - cars.rb:**
```ruby
# 第1-2行
# 清空现有数据
Car.destroy_all
```

**问题:**
- ⚠️ **与 rake 任务冲突**: `validator.rake` 已经在 Step 1 清空整个数据库
- **执行两次清理**: rake清空整库 → 数据包内又`destroy_all`
- **性能损耗**: 每个数据包单独清理,而不是利用已清空的数据库
- **逻辑混乱**: 如果数据包单独运行,清理是必要的;但通过rake运行时是冗余的

---

#### ❌ 问题5: 文件命名不一致
**现状:**
```
hotels_all.rb          # 统一命名
tour_group_products_all.rb  # 加了后缀
chartered_tours_all_cities.rb  # 描述性后缀

flights.rb            # 简单命名
trains.rb
cars.rb

attractions.rb        # 无后缀
cruises.rb

z_homestays_supplement.rb  # z_前缀
z_hotel_packages_associations.rb
```

**问题:**
- `_all` 后缀含义不明: 是"所有城市"还是"统一文件"?
- 无法从文件名判断是否是主文件还是补充文件

---

### 2. **数据包依赖关系分析**

#### 🔗 明确的依赖链:

```
base.rb (基础数据: City, Destination)
  ↓
flights.rb, trains.rb, hotels_all.rb, attractions.rb, cars.rb, ...  (主业务数据)
  ↓
hotels_for_packages.rb (依赖 Hotel 存在)
  ↓  
hotel_packages.rb (创建套餐)
  ↓
z_hotel_packages_associations.rb (关联套餐与酒店)
  ↓
hotels_phase2_fields_update.rb (字段更新)
  ↓
hotels_all_fix.rb (价格修复)
```

**问题:** 
- 当前的字母排序无法保证这个依赖链正确执行
- 例如:`hotels_all_fix.rb` 可能在 `hotels_for_packages.rb` 之前加载(字母h < h)

---

### 3. **各数据包具体问题清单**

| 文件名 | 行数 | 问题类型 | 具体问题 |
|--------|------|----------|----------|
| `hotels_all_fix.rb` | 20 | 命名/职责 | 应该合并到 hotels_all.rb 结尾 |
| `hotels_for_packages.rb` | 228 | 依赖顺序 | 依赖 Hotel 已存在,但无法保证 |
| `hotels_phase2_fields_update.rb` | 74 | 职责分散 | Phase2字段应在主文件中处理 |
| `z_hotel_packages_associations.rb` | 69 | z_前缀混乱 | 用z_保证顺序是hack做法 |
| `flights_supplement.rb` | 173 | 职责不清 | supplement含义模糊 |
| `flights_phase2_fields_update.rb` | 39 | 命名不一致 | 与其他模块的_extended不一致 |
| `trains_extended.rb` | 163 | 命名不一致 | 应该统一用supplement还是extended? |
| `cars_supplement.rb` | 134 | 重复清理 | 重复 destroy_all |
| `bus_tickets_supplement.rb` | 81 | 职责不清 | 补充什么? |
| `tour_groups_supplement.rb` | 117 | 职责不清 | 与主文件界限模糊 |
| `z_homestays_supplement.rb` | 140 | z_前缀混乱 | 为什么homestays需要z_? |
| `phase2_extended_scenarios.rb` | 265 | 命名模糊 | 跨模块的扩展场景 |
| `phase2_missing_data.rb` | 421 | 命名模糊 | 什么数据missing? |

---

## ✅ 重构方案

### 方案目标:
1. ~~**消除依赖顺序问题**: 通过显式依赖声明管理加载顺序~~ ❌ **不采用**
2. **合并分散文件**: 同一模块数据整合到单一文件 ✅ **执行**
3. **统一命名规范**: 清晰的命名约定 ✅ **执行**
4. **移除冗余清理**: 利用rake任务的全局清理 ✅ **执行**
5. **提升可维护性**: 降低认知负担,易于扩展 ✅ **执行**

---

### 🎯 采用方案: 简化重构方案 (保持现有加载机制)

**原则:** 保持现有字母排序加载机制，通过文件合并和命名规范解决问题

#### 核心策略

**不引入配置文件**, 利用现有的 `Dir.glob().sort` 字母排序机制：
- `base.rb` 已经通过代码优先加载（validator.rake 第110-115行）
- 其他文件按字母顺序加载即可
- **关键**: 所有依赖逻辑合并到同一个文件内，按步骤顺序执行

#### 实施步骤

**步骤 1: 移除所有数据包内的 destroy_all（base.rb 除外）**

**原因:** `rake validator:reset_baseline` 在 Step 1 已经清空整个数据库

```ruby
# ❌ WRONG - 冗余清理
Hotel.destroy_all
HotelRoom.destroy_all

# ✅ CORRECT - 直接插入
puts "正在加载 hotels_v1 数据包..."
Hotel.insert_all(hotels_data)
```

**步骤 2: 合并 hotels 相关文件 → hotels.rb**

将以下文件合并为单一的 `hotels.rb`:
- `hotels_all.rb` (747行)
- `hotels_for_packages.rb` (228行) 
- `hotels_phase2_fields_update.rb` (74行)
- `hotels_all_fix.rb` (20行)
- `z_hotel_packages_associations.rb` (69行)

**合并后的文件结构:**

**步骤 3: 合并 flights 相关文件 → flights.rb**

将以下文件合并:
- `flights.rb` (1579行)
- `flights_supplement.rb` (173行)
- `flights_phase2_fields_update.rb` (39行)

**步骤 4: 合并 trains 相关文件 → trains.rb**

将以下文件合并:
- `trains.rb` (970行)
- `trains_extended.rb` (163行)

**步骤 5: 合并 cars 相关文件 → cars.rb**

将以下文件合并:
- `cars.rb` (2100行)
- `cars_supplement.rb` (134行)

**步骤 6: 重命名不规范文件**

标准化文件命名:
- `tour_group_products_all.rb` → `tour_group_products.rb`
- `chartered_tours_all_cities.rb` → `chartered_tours.rb`
- 移除所有 `z_` 前缀（除非有明确的加载顺序需求）

**步骤 7: 清理 phase2 文件**

将 phase2 相关逻辑合并到对应的主文件中:
- `phase2_extended_scenarios.rb` → 拆分到各业务模块
- `phase2_missing_data.rb` → 拆分到各业务模块

---

### 🚫 不采用方案: 彻底重构方案（目录结构）

**原则:** 重新组织目录结构,按业务模块分类

**❌ 此方案不采用 - 原因:**
- 引入过多复杂性
- 需要修改 rake 任务加载逻辑
- 字母排序机制已经足够简单有效
- 文件合并可以解决大部分问题

**保留此部分仅供参考:**

#### B1. 新目录结构

```
app/validators/support/data_packs/v1/
├── 00_base/
│   ├── cities.rb           # City数据
│   ├── destinations.rb     # Destination数据
│   └── users.rb            # Demo用户
│
├── 10_flights/
│   ├── flights_main.rb     # 主航班数据
│   ├── flights_premium.rb  # 高端航班
│   └── flight_packages.rb  # 航班套餐
│
├── 20_trains/
│   ├── trains_main.rb      # 主火车数据
│   └── trains_extended.rb  # 扩展场景
│
├── 30_hotels/
│   ├── hotels_main.rb      # 统一创建Hotel + HotelRoom + 价格修复
│   ├── hotel_packages.rb   # 酒店套餐
│   └── hotel_packages_associations.rb  # 关联
│
├── 40_attractions/
│   └── attractions_main.rb  # 景点+门票+活动
│
├── 50_cars/
│   └── cars_main.rb        # 租车
│
├── 60_tours/
│   ├── tour_products.rb     # 跟团游
│   └── chartered_tours.rb   # 包车游
│
├── 70_services/
│   ├── insurances.rb       # 保险
│   ├── visas.rb            # 签证
│   ├── internet.rb         # 境外上网
│   ├── transfers.rb        # 接送机
│   └── deep_travel.rb      # 深度旅行
│
├── 80_shopping/
│   ├── abroad_shopping.rb  # 境外购物
│   └── abroad_tickets.rb   # 境外门票
│
├── 90_membership/
│   ├── membership_products.rb
│   └── live_products.rb
│
└── _load_order.rb          # 自动加载所有模块
```

#### B2. 加载器实现

```ruby
# app/validators/support/data_packs/v1/_load_order.rb

module DataPacksV1
  class Loader
    LOAD_ORDER = [
      '00_base',
      '10_flights',
      '20_trains',
      '30_hotels',
      '40_attractions',
      '50_cars',
      '60_tours',
      '70_services',
      '80_shopping',
      '90_membership'
    ]
    
    def self.load_all
      base_dir = File.dirname(__FILE__)
      
      LOAD_ORDER.each do |dir_name|
        dir_path = File.join(base_dir, dir_name)
        
        unless Dir.exist?(dir_path)
          puts "⚠️  目录不存在: #{dir_name}"
          next
        end
        
        puts "\n📂 加载模块: #{dir_name}"
        
        # 按文件名排序加载该目录下所有.rb文件
        Dir.glob(File.join(dir_path, '*.rb')).sort.each do |file|
          filename = File.basename(file)
          print "  → #{filename}..."
          
          begin
            load file
            puts " ✓"
          rescue StandardError => e
            puts " ✗"
            puts "    错误: #{e.message}"
            raise
          end
        end
      end
    end
  end
end

# 如果直接运行此文件,则加载所有数据包
if __FILE__ == $0
  DataPacksV1::Loader.load_all
end
```

#### B3. 合并 hotels 模块示例

```ruby
# app/validators/support/data_packs/v1/30_hotels/hotels_main.rb

require_relative '../../../../../../app/helpers/image_seed_helper'

puts "正在加载 hotels_main 数据包..."

timestamp = Time.current

# ==================== 城市和品牌配置 ====================
cities = ["深圳", "上海", "北京", "广州", "杭州", "成都", ...]

international_brands = [...]
domestic_brands = [...]

# ==================== 批量创建酒店 ====================
puts "\n🏨 批量创建酒店..."
hotels_data = []

# ... (合并 hotels_all.rb 的主要逻辑)

Hotel.insert_all(hotels_data)

# ==================== 创建房间 ====================
puts "\n🛏️  批量创建房间..."
# ... (合并 hotels_all.rb 的房间创建逻辑)

# ==================== 为套餐补充酒店 (原 hotels_for_packages.rb) ====================
puts "\n🏨 为套餐补充匹配酒店..."
# ... (合并 hotels_for_packages.rb 逻辑)

# ==================== Phase2 字段更新 (原 hotels_phase2_fields_update.rb) ====================
puts "\n🔧 更新Phase2字段..."
# ... (合并 hotels_phase2_fields_update.rb 逻辑)

# ==================== 价格同步修复 (原 hotels_all_fix.rb) ====================
puts "\n🔧 同步酒店价格为实际最低房价..."
fixed_count = 0
Hotel.find_each do |hotel|
  min_room_price = hotel.hotel_rooms.minimum(:price)
  next if min_room_price.nil?
  next if hotel.price == min_room_price
  
  hotel.update_column(:price, min_room_price)
  fixed_count += 1
end
puts "✓ 已同步 #{fixed_count} 家酒店价格"

puts "✅ hotels_main 数据包加载完成"
```

---

### 🚫 不采用方案: 混合方案

**❌ 此方案不采用 - 原因:**
- 不需要分阶段，直接采用简化方案一次性完成
- 避免引入 load_order.yml 配置文件增加复杂度

---

## 📊 方案对比

| 维度 | 简化方案 (采用) | 配置文件方案 (不采用) | 目录重构方案 (不采用) |
|------|------------------|------------------|--------------|
| **实施难度** | ⭐⭐ 低 | ⭐⭐⭐ 中 (引入配置) | ⭐⭐⭐⭐⭐ 高 |
| **实施时间** | 1-2天 | 1-2天 (但引入新复杂度) | 2-3周 |
| **代码变动量** | 中 (合并文件) | 中 (合并文件+配置) | 大 (重组所有文件) |
| **可维护性提升** | ⭐⭐⭐⭐ 高 | ⭐⭐⭐ 中 (多一层配置) | ⭐⭐⭐⭐⭐ 高 (但过度设计) |
| **风险** | ⭐ 低 | ⭐⭐ 低 (多一个配置文件) | ⭐⭐⭐⭐ 高 |
| **可扩展性** | ⭐⭐⭐⭐ 高 (足够用) | ⭐⭐⭐⭐ 高 (不必要) | ⭐⭐⭐⭐⭐ 高 (过度) |
| **回滚难度** | ⭐ 易 | ⭐⭐ 易 | ⭐⭐⭐⭐⭐ 难 |
| **是否采用** | ✅ **是** | ❌ 否 | ❌ 否 |

---

## 🚀 实施步骤 (简化方案)

### 任务清单

- [ ] **任务1**: 移除所有数据包文件中的 destroy_all 语句（base.rb 除外）
- [ ] **任务2**: 合并 hotels 相关文件 → hotels.rb (5个文件合并)
- [ ] **任务3**: 合并 flights 相关文件 → flights.rb (3个文件合并)
- [ ] **任务4**: 合并 trains 相关文件 → trains.rb (2个文件合并)
- [ ] **任务5**: 合并 cars 相关文件 → cars.rb (2个文件合并)
- [ ] **任务6**: 重命名其他不规范文件名（tour_group_products_all.rb → tour_group_products.rb 等）
- [ ] **任务7**: 测试数据包加载：运行 `rake validator:reset_baseline` 确保无错误
- [ ] **任务8**: 测试验证器：运行 `rake validator:simulate` 确保所有验证器通过

### 实施原则

1. **一次一个模块**: 从 hotels 开始，完成一个测试一个
2. **保留原文件**: 合并前先备份，测试通过后再删除
3. **立即测试**: 每次修改后立即运行 `rake validator:reset_baseline`
4. **记录问题**: 遇到问题及时记录，避免重复错误

---

## 📝 关键决策记录

### 为什么不使用 load_order.yml？

1. **现有机制足够**: `Dir.glob().sort` 字母排序 + `base.rb` 优先加载已经满足需求
2. **避免过度设计**: 引入配置文件增加一层抽象，但收益有限
3. **依赖应在文件内**: 将依赖逻辑合并到同一文件内更直观，而不是通过配置文件控制顺序
4. **简单即美**: 保持加载机制简单，降低维护成本

### 为什么不使用目录结构重组？

1. **过度设计**: 当前文件数量不多（约40个），平铺足够
2. **修改成本高**: 需要修改 rake 任务，增加复杂度
3. **文件合并已足够**: 通过合并分散文件，可以减少到20个左右，管理难度不大

### 核心理念

**YAGNI (You Aren't Gonna Need It)** - 不要过早优化，保持简单有效的解决方案

---

## 📚 相关文档

- `lib/tasks/validator.rake` - 数据包加载任务
- `app/validators/` - 所有验证器
- `.clackyrules` - 数据包使用规范

---

## 📚 相关规范

所有数据包开发规范已写入 `.clackyrules` 文件，包括：

- **文件组织规则**: ONE Business Module = ONE Data Pack File
- **命名规范**: 使用简单复数名（flights.rb, trains.rb, hotels.rb）
- **禁止模式**: 不允许 `_supplement`, `_extended`, `_phase2`, `_fix` 等后缀
- **destroy_all 规则**: 只有 base.rb 可以使用，其他文件禁止
- **依赖管理**: 所有依赖逻辑必须在同一文件内按步骤组织

详见 `.clackyrules` 中的 "Data Packs - Test/Validation Data Management" 章节。

---

**文档创建时间:** 2026-02-03  
**文档更新时间:** 2026-02-03  
**文档作者:** AI Assistant  
**状态:** ✅ 方案确定 (简化方案)
