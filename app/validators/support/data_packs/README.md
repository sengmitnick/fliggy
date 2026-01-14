# 验证数据包说明

## 🎯 统一数据管理策略

**所有数据通过 data_packs 版本化管理，降低维护成本**

```
app/validators/support/data_packs/v1/
├── base.rb          # 基础数据：City, Destination, Demo用户（永久保留）
├── flights.rb       # 航班测试数据（6个航班）
├── hotels_seed.rb   # 酒店测试数据
├── trains.rb        # 火车测试数据（待创建）
└── ...              # 其他业务数据包

db/seeds.rb          # 空入口，仅提供使用说明
```

## 核心理念

### 1. 初始状态：数据库为空

项目启动后，数据库默认为空，无任何预置数据。

### 2. 按需加载策略

- **基础数据**（City, Destination）：验证器运行时自动加载
- **业务数据**（Flight, Hotel 等）：各验证器根据需要加载对应的 data_pack
- **用户数据**（订单、乘客等）：验证过程中产生，验证后清除

### 3. 版本化管理

所有数据包采用版本化命名：
- `v1/base.rb` - 基础数据版本 1
- `v1/flights.rb` - 航班数据版本 1
- `v2/flights.rb` - 航班数据版本 2（当需要修改时创建新版本）

### 4. 数据隔离

- **基础数据**（City, Destination）：永久保留，所有验证器共享
- **测试数据**（Flight, Hotel 等）：验证器独占，验证后清除
- **订单数据**（Booking, HotelBooking 等）：验证过程产生，验证后清除

## 目录结构

```
app/validators/support/data_packs/
├── ARCHITECTURE.md     # 架构详细文档
├── README.md           # 本说明文档
├── MIGRATION_SUMMARY.md # 迁移总结（历史记录）
└── v1/
    ├── base.rb         # 基础数据：City (240个), Destination, Demo用户
    ├── flights.rb      # 航班数据：6个测试航班
    ├── hotels_seed.rb  # 酒店数据：深圳地区酒店
    └── ...             # 其他业务数据包
```

## 数据包规范

### 文件命名

- 格式：`v<version>/<domain>.rb`
- 示例：`v1/flights.rb`, `v1/hotels.rb`, `v2/trains.rb`
- version：版本号（v1, v2, v3...）
- domain：业务领域（flights, hotels, trains等）

### 文件结构

```ruby
# frozen_string_literal: true

# <domain>_v<version> 数据包
# 用于 <具体验证任务描述>
#
# 数据说明：
# - <数据集1描述>
# - <数据集2描述>

puts "正在加载 <domain>_v<version> 数据包..."

# ==================== 动态日期设置 ====================
base_date = Date.current + 3.days  # 使用动态日期
base_datetime = base_date.to_time.in_time_zone

# ==================== 数据创建 ====================
[
  {
    field1: "value1",
    field2: 100,
    date_field: base_date  # 使用动态日期
  }
].each do |attrs|
  Model.create!(attrs)
end

puts "✓ <domain>_v<version> 数据包加载完成（<数量>条记录）"
```

### 最佳实践

1. **明确数据用途**：在注释中说明数据包的用途和特征
2. **使用动态日期**：使用 `Date.current + N.days` 而不是固定日期
3. **输出清晰日志**：加载开始和结束时输出日志，便于调试
4. **数据关联正确**：确保外键关联正确（如 Flight 的 departure_city 必须在 City 表中存在）
5. **不使用显式 ID**：让数据库自动生成 ID，避免冲突

#### 动态日期示例

```ruby
# ✅ 正确：使用动态日期
base_date = Date.current + 3.days
base_datetime = base_date.to_time.in_time_zone

Flight.create!(
  departure_time: base_datetime.change(hour: 8, min: 0),
  arrival_time: base_datetime.change(hour: 11, min: 30),
  flight_date: base_date
)

# ❌ 错误：使用固定日期（会过期）
Flight.create!(
  departure_time: Time.zone.parse("2024-12-20 08:00:00"),
  arrival_time: Time.zone.parse("2024-12-20 11:30:00"),
  flight_date: Date.parse("2024-12-20")
)
```

**重要：** 验证器的 `prepare` 方法也必须使用相同的动态日期逻辑！

```ruby
# 在验证器中
class YourValidator < BaseValidator
  def prepare
    @target_date = Date.current + 3.days  # 与数据包保持一致
    # ...
  end
end
```

## 现有数据包

### base.rb（基础数据包）

**用途**：所有验证器的依赖数据

**数据内容**：
- City：240+ 城市（中国 + 国际热门城市）
- Destination：目的地数据，与 City 关联
- Demo用户：demo@fliggy.com（密码：password123，支付密码：222222）
- 默认乘客：张三（身份证：110101199001011234）

**加载时机**：
- BaseValidator#ensure_checkpoint 自动检查并加载
- 或手动运行：`rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"`

### flights.rb（航班数据包）

**用途**：航班预订验证任务

**数据内容**：
- 深圳市→北京市：4个航班，价格区间 550-1200 元（最低价 550 元）
- 上海市→深圳市：2个航班，价格区间 450-520 元（最低价 450 元）
- 使用动态日期：今天+3天

**适用验证**：
- `BookFlightValidator`：预订最低价航班
- `SearchCheapestFlightValidator`：搜索折扣后最低价

### hotels_seed.rb（酒店数据包）

**用途**：酒店预订演示数据

**数据内容**：
- 深圳地区的酒店数据
- 包含房间、设施、政策等信息

**注意**：此文件待迁移整合到 `hotels.rb`

## 使用方式

### 方式 1: 通过验证器自动加载（推荐）

```ruby
# 验证器会自动加载所需数据包
validator = BookFlightValidator.new
validator.execute_prepare  # 自动加载 base.rb + v1/flights.rb
```

### 方式 2: 手动加载基础数据

```bash
# 只加载基础数据（City + Destination）
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
```

### 方式 3: 手动加载完整演示数据

```bash
# 1. 加载基础数据
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"

# 2. 加载航班数据
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')"

# 3. 加载酒店数据
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/hotels_seed.rb')"
```

### 方式 4: 通过 db:seed 加载（会显示使用说明）

```bash
rails db:seed
# 输出使用说明和手动加载命令
```

## 创建新数据包

### 步骤

1. **创建文件**：`app/validators/support/data_packs/v1/<domain>.rb`
2. **编写数据**：参考上述文件结构和最佳实践
3. **创建验证器**：在 `app/validators/` 中创建对应的验证器类
4. **指定版本**：在验证器中设置 `self.data_pack_version = 'v1/<domain>'`
5. **测试验证**：使用 CLI 或 API 测试完整流程

### 示例：创建 trains.rb 数据包

```ruby
# app/validators/support/data_packs/v1/trains.rb
# frozen_string_literal: true

# trains_v1 数据包
# 用于火车票预订验证任务
#
# 数据说明：
# - 深圳市→北京市：2个车次
# - 使用动态日期：今天+3天

puts "正在加载 trains_v1 数据包..."

base_date = Date.current + 3.days

[
  {
    train_number: "G1234",
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_date.to_time.in_time_zone.change(hour: 8, min: 0),
    arrival_time: base_date.to_time.in_time_zone.change(hour: 17, min: 30),
    price: 933.5,
    available_seats: 100,
    train_date: base_date
  }
].each do |attrs|
  Train.create!(attrs)
end

puts "✓ trains_v1 数据包加载完成（1个车次）"
```

### 在验证器中使用

```ruby
class BookTrainValidator < BaseValidator
  self.validator_id = 'book_train'
  self.title = '预订火车票'
  self.data_pack_version = 'v1/trains'  # 指定数据包版本
  self.timeout_seconds = 300
  
  def prepare
    # 数据已通过 load_data_pack 自动加载
    @target_date = Date.current + 3.days
    @origin = '深圳市'
    @destination = '北京市'
    
    {
      task: "请预订一张#{@origin}到#{@destination}的火车票",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s
    }
  end
  
  def verify
    # 验证逻辑
    add_assertion "订单已创建", weight: 50 do
      booking = TrainBooking.order(created_at: :desc).first
      expect(booking).not_to be_nil
    end
  end
  
  private
  
  def execution_state_data
    { target_date: @target_date.to_s, origin: @origin, destination: @destination }
  end
  
  def restore_from_state(data)
    @target_date = Date.parse(data['target_date'])
    @origin = data['origin']
    @destination = data['destination']
  end
end
```

## 版本迭代

当需要修改数据时：

1. **创建新版本**：复制为 `v2/<domain>.rb`
2. **修改数据**：在新文件中进行修改
3. **更新验证器**：修改 `data_pack_version = 'v2/<domain>'`
4. **保留旧版本**：不删除旧文件，保持向后兼容

示例：

```ruby
# v1/flights.rb - 旧版本，6个航班
# v2/flights.rb - 新版本，10个航班，增加了更多航线

# 新验证器使用 v2
class BookFlightV2Validator < BaseValidator
  self.data_pack_version = 'v2/flights'
end

# 旧验证器仍使用 v1
class BookFlightValidator < BaseValidator
  self.data_pack_version = 'v1/flights'
end
```

## 数据包工作流程

### 验证器执行流程

```
1. execute_prepare
   ├─ ensure_checkpoint()        # 确保基础数据存在（base.rb）
   ├─ reset_test_data_only()     # 清空测试数据表
   ├─ load_data_pack()           # 加载验证器专用数据包
   ├─ prepare()                  # 验证器自定义准备
   └─ save_execution_state()     # 保存执行状态

2. [Agent 操作]
   用户通过界面完成任务（如创建订单）

3. execute_verify
   ├─ restore_execution_state()  # 恢复执行状态
   ├─ verify()                   # 验证结果
   ├─ cleanup_execution_state()  # 清理执行状态
   └─ rollback_to_checkpoint()   # 回滚到 checkpoint
```

### Checkpoint 机制

**Checkpoint = base.rb 加载完成后的数据库状态**

- ✅ 包含：City, Destination, Demo用户
- ❌ 不包含：Flight, Hotel, Train 等业务数据
- ❌ 不包含：Booking, HotelBooking 等订单数据

**作用**：
- 验证前：确保基础数据存在（ensure_checkpoint）
- 验证后：清除测试数据和订单，保留基础数据（rollback_to_checkpoint）

## 注意事项

1. **不要修改已发布的数据包**：创建新版本而非修改现有版本
2. **确保数据完整性**：外键关联必须正确（如 Flight 的 departure_city 必须在 City 表中存在）
3. **必须使用动态日期**：使用 `Date.current + N.days` 而不是 `Date.parse('2024-12-20')`
4. **测试数据真实性**：数据应接近真实场景
5. **验证器日期一致性**：验证器的 `prepare` 方法必须使用与数据包相同的日期逻辑
6. **不要在 db/seeds.rb 中添加数据**：所有数据统一在 data_packs 管理

## 常见问题

### Q: 为什么不在 db/seeds.rb 中加载数据？

A: 统一管理降低维护成本。所有数据通过 data_packs 版本化管理，避免 seeds.rb 和 data_packs 重复维护。

### Q: 如何查看当前数据库状态？

A: 使用 rails console:
```ruby
City.count         # 基础数据
Flight.count       # 测试数据
Booking.count      # 订单数据
```

### Q: prepare 后为什么 Flight.count != 0？

A: 这是正确的。prepare 加载的数据是持久化的，供用户操作使用。verify 完成后会通过 rollback_to_checkpoint 清除。

### Q: 如何清空所有数据重新开始？

A: 
```bash
# 方式1: 重置数据库
rails db:reset

# 方式2: 手动清空
rails runner "Flight.delete_all; Booking.delete_all; City.delete_all; Destination.delete_all"

# 然后重新加载基础数据
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
```

### Q: 能否在一个验证器中使用多个数据包？

A: 可以。重写 `load_data_pack` 方法：

```ruby
class ComplexValidator < BaseValidator
  self.data_pack_version = 'v1/complex'
  
  def load_data_pack
    load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')
    load Rails.root.join('app/validators/support/data_packs/v1/hotels.rb')
    load Rails.root.join('app/validators/support/data_packs/v1/trains.rb')
  end
end
```

## 相关文件

- `db/seeds.rb`: 空入口，提供使用说明
- `app/validators/support/data_packs/v1/base.rb`: 基础数据包
- `app/validators/support/data_packs/v1/*.rb`: 各业务数据包
- `app/validators/support/data_packs/ARCHITECTURE.md`: 架构详细文档
- `app/validators/base_validator.rb`: 数据包加载逻辑
- `app/validators/*_validator.rb`: 具体验证器实现
