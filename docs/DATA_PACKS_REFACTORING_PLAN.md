# 数据包重构方案 (Data Packs Refactoring Plan)

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
1. **消除依赖顺序问题**: 通过显式依赖声明管理加载顺序
2. **合并分散文件**: 同一模块数据整合到单一文件
3. **统一命名规范**: 清晰的命名约定
4. **移除冗余清理**: 利用rake任务的全局清理
5. **提升可维护性**: 降低认知负担,易于扩展

---

### 🎯 方案A: 最小改动方案 (推荐短期)

**原则:** 在现有结构基础上,通过配置文件显式声明依赖关系

#### A1. 创建依赖配置文件

```ruby
# app/validators/support/data_packs/v1/load_order.yml
---
load_order:
  # Phase 1: 基础数据 (无依赖)
  - base.rb
  - demo_user.rb
  
  # Phase 2: 主业务数据 (依赖基础数据)
  - flights.rb
  - trains.rb
  - hotels_all.rb
  - cars.rb
  - attractions.rb
  - cruises.rb
  - bus_tickets.rb
  - tour_group_products_all.rb
  - chartered_tours_all_cities.rb
  - deep_travel_venues.rb
  - insurances.rb
  - visa_services.rb
  - internet_services.rb
  - membership_products.rb
  - transfers.rb
  - abroad_shopping.rb
  - abroad_tickets.rb
  - pickup_locations.rb
  - live_products.rb
  
  # Phase 3: 补充数据 (依赖主数据)
  - flights_supplement.rb
  - premium_flights.rb
  - flight_packages.rb
  - trains_extended.rb
  - cars_supplement.rb
  - bus_tickets_supplement.rb
  - tour_groups_supplement.rb
  - deep_travel_reviews.rb
  - hotels_for_packages.rb
  
  # Phase 4: 关联数据 (依赖多个主数据)
  - hotel_packages.rb
  - z_hotel_packages_associations.rb
  - z_homestays_supplement.rb
  
  # Phase 5: 字段更新和修复 (依赖所有数据已创建)
  - flights_phase2_fields_update.rb
  - hotels_phase2_fields_update.rb
  - phase2_extended_scenarios.rb
  - phase2_missing_data.rb
  - hotels_all_fix.rb
```

#### A2. 修改 rake 任务

```ruby
# lib/tasks/validator.rake (第99-139行替换为:)

# Step 2: 重新加载数据包
puts "\n📦 Step 2: 重新加载数据包..."

# 设置固定随机种子
srand(20250131)
puts "  → 设置固定随机种子: srand(20250131)"

# 设置 PostgreSQL 会话变量 app.data_version='0'
ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '0'")

# 读取加载顺序配置
data_packs_dir = Rails.root.join('app/validators/support/data_packs/v1')
load_order_file = data_packs_dir.join('load_order.yml')

unless File.exist?(load_order_file)
  puts "\n❌ 加载顺序配置文件不存在: #{load_order_file}"
  exit 1
end

load_order_config = YAML.load_file(load_order_file)
data_pack_files = load_order_config['load_order'].map { |f| data_packs_dir.join(f).to_s }

# 验证所有文件存在
missing_files = data_pack_files.reject { |f| File.exist?(f) }
if missing_files.any?
  puts "\n❌ 以下数据包文件不存在:"
  missing_files.each { |f| puts "  → #{File.basename(f)}" }
  exit 1
end

# 加载所有数据包
loaded_files = []
data_pack_files.each do |file|
  filename = File.basename(file)
  print "  → 加载 #{filename}..."
  begin
    load file
    loaded_files << filename
    puts " ✓"
  rescue StandardError => e
    puts " ✗"
    puts "    错误: #{e.message}"
    puts "\n❌ 数据包加载失败，回滚操作..."
    
    # 删除已加载的数据
    DataVersionable.models.reverse.each do |model|
      model.where(data_version: 0).destroy_all
    end
    
    exit 1
  end
end
```

#### A3. 消除数据包内的 destroy_all

**创建一个脚本批量处理:**

```bash
# scripts/remove_destroy_all_from_data_packs.sh
#!/bin/bash

DATA_PACK_DIR="app/validators/support/data_packs/v1"

# 备份
cp -r "$DATA_PACK_DIR" "${DATA_PACK_DIR}.backup"

# 移除 destroy_all 语句 (保留中文注释行)
for file in "$DATA_PACK_DIR"/*.rb; do
  # 跳过 base.rb
  if [[ $(basename "$file") == "base.rb" ]]; then
    continue
  fi
  
  # 注释掉 destroy_all 行 (不是注释行的才注释)
  sed -i.bak '/^[^#]*destroy_all/s/^/# [REMOVED by refactoring] /' "$file"
  
  # 删除 backup 文件
  rm "${file}.bak"
  
  echo "✓ Processed: $(basename "$file")"
done

echo "✅ All destroy_all statements have been commented out"
echo "📁 Original files backed up to: ${DATA_PACK_DIR}.backup"
```

---

### 🎯 方案B: 彻底重构方案 (推荐长期)

**原则:** 重新组织目录结构,按业务模块分类

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

### 🎯 方案C: 混合方案 (平衡短期与长期)

**策略:**
1. **第一阶段 (2周内)**: 实施方案A,解决最紧急的依赖顺序问题
2. **第二阶段 (1个月内)**: 逐步合并分散文件,减少文件数量
3. **第三阶段 (2-3个月)**: 根据实际情况决定是否完全重构为方案B

**第一阶段任务清单:**
- [ ] 创建 `load_order.yml`
- [ ] 修改 `validator.rake` 使用配置文件
- [ ] 移除所有数据包内的 `destroy_all`
- [ ] 测试确保所有验证器通过

**第二阶段任务清单:**
- [ ] 合并 hotels 相关文件 → `hotels.rb`
- [ ] 合并 flights 相关文件 → `flights.rb`
- [ ] 合并 trains 相关文件 → `trains.rb`
- [ ] 合并 cars 相关文件 → `cars.rb`
- [ ] 重命名 `phase2_*` 文件为更清晰的名称
- [ ] 删除 `z_` 前缀,依靠配置文件管理顺序

**第三阶段任务清单:**
- [ ] 评估是否需要按业务模块分目录
- [ ] 如果需要,逐步迁移到方案B的目录结构

---

## 📊 方案对比

| 维度 | 方案A (最小改动) | 方案B (彻底重构) | 方案C (混合) |
|------|------------------|------------------|--------------|
| **实施难度** | ⭐ 低 | ⭐⭐⭐⭐⭐ 高 | ⭐⭐⭐ 中 |
| **实施时间** | 1-2天 | 2-3周 | 分阶段 (总2-3个月) |
| **代码变动量** | 小 (仅rake + 配置) | 大 (重组所有文件) | 中等 (逐步重构) |
| **可维护性提升** | ⭐⭐⭐ 中 | ⭐⭐⭐⭐⭐ 高 | ⭐⭐⭐⭐ 高 |
| **风险** | ⭐ 低 | ⭐⭐⭐⭐ 高 | ⭐⭐ 低 |
| **可扩展性** | ⭐⭐ 中 | ⭐⭐⭐⭐⭐ 高 | ⭐⭐⭐⭐ 高 |
| **回滚难度** | ⭐ 易 | ⭐⭐⭐⭐⭐ 难 | ⭐⭐⭐ 中 |

---

## 🚀 推荐实施步骤 (方案C)

### 第一步: 紧急修复 (本周完成)
1. 创建 `load_order.yml`
2. 修改 `validator.rake`
3. 测试所有验证器

### 第二步: 逐步合并 (下周开始)
1. 从最严重的 hotels 模块开始
2. 每合并一个模块,立即测试
3. 保留原文件作为备份

### 第三步: 持续优化 (后续)
1. 收集使用反馈
2. 根据实际情况调整结构
3. 文档化最佳实践

---

## 📝 待讨论的问题

1. **是否需要立即行动?**
   - 如果当前系统运行稳定,可以暂缓
   - 如果频繁遇到数据加载问题,建议立即实施方案A

2. **是否需要彻底重构?**
   - 如果团队规模扩大,数据包频繁修改 → 方案B
   - 如果维护团队稳定,数据包变动不频繁 → 方案A足够

3. **如何保证兼容性?**
   - 所有变更必须通过 `rake validator:simulate` 验证
   - 建议在独立分支进行,测试通过后合并

---

## 📚 相关文档

- `lib/tasks/validator.rake` - 数据包加载任务
- `app/validators/` - 所有验证器
- `.clackyrules` - 数据包使用规范

---

**文档创建时间:** 2026-02-03  
**文档作者:** AI Assistant  
**状态:** 草案 (待讨论)
