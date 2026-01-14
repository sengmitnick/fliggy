# 验证器系统设计文档

## 📖 目录

- [概述](#概述)
- [核心设计理念](#核心设计理念)
- [架构设计](#架构设计)
- [核心亮点](#核心亮点)
- [技术实现](#技术实现)
- [使用示例](#使用示例)
- [最佳实践](#最佳实践)

---

## 概述

验证器系统（Validator System）是一个用于自动化验证 AI Agent 任务完成质量的框架。它通过 **Checkpoint 机制** 和 **数据持久化设计**，实现了可靠、可重复的端到端测试。

### 核心特性

- ✅ **Checkpoint 机制**: 智能数据库状态管理，避免重复加载 seeds
- ✅ **数据持久化**: 验证期间数据始终可用，支持真实用户操作
- ✅ **RSpec 风格 DSL**: 简洁易读的断言语法
- ✅ **状态隔离**: 跨阶段状态持久化，prepare → verify 无缝衔接
- ✅ **版本化数据包**: 灵活的测试数据管理
- ✅ **交互式 CLI**: 友好的命令行工具

---

## 核心设计理念

### 1. 数据库 Checkpoint 机制

**核心思想**: 数据库有三种状态：

```
┌─────────────┐
│  空数据库    │ → 首次运行
└─────────────┘
       ↓ rails db:seed
┌─────────────┐
│  Checkpoint │ → 完整 seeds 数据（City、Destination、Flight、Hotel 等）
│  基准状态    │   这是验证器的"干净起点"
└─────────────┘
       ↓ validator prepare（加载专有数据包）
┌─────────────┐
│  测试状态    │ → Checkpoint + 验证器专有数据
│  运行中      │   用户可在此状态下操作
└─────────────┘
       ↓ validator verify（验证后回滚）
┌─────────────┐
│  Checkpoint │ → 清空测试数据和订单，重新加载 seeds
│  基准状态    │   准备下次验证
└─────────────┘
```

**关键优化**:
- ✅ **智能检测**: `ensure_checkpoint` 检查 City 和 Flight 表，避免重复加载
- ✅ **最小重置**: 只清空测试数据，保留基础数据（City/Destination）
- ✅ **自动回滚**: 验证完成后自动恢复到 checkpoint 状态

### 2. 数据持久化设计

**核心问题**: 传统测试框架使用事务回滚，导致验证期间数据消失。

**解决方案**: 移除事务包裹，数据直接提交到数据库。

```ruby
# ❌ 传统做法（数据会消失）
ActiveRecord::Base.transaction do
  load_data_pack
  # 用户操作...
  raise ActiveRecord::Rollback  # 数据消失！
end

# ✅ 新设计（数据持久化）
def execute_prepare
  ensure_checkpoint           # 检查/创建 checkpoint
  reset_test_data_only        # 清空测试表
  load_data_pack              # 加载验证器专有数据（持久化！）
  save_execution_state        # 保存状态到数据库
  # 数据保留，用户可以操作
end
```

**优势**:
- ✅ 用户在等待期间可以正常查看和操作数据
- ✅ 验证阶段直接验证真实数据库状态
- ✅ 回滚由专门方法控制，而非事务自动回滚

### 3. 状态持久化

**挑战**: prepare 和 verify 在不同请求中执行，如何传递状态？

**解决方案**: 使用数据库表 `validator_executions` 存储执行状态。

```ruby
# app/validators/base_validator.rb

# Prepare 阶段保存状态
def save_execution_state
  state = {
    validator_class: self.class.name,
    timestamp: Time.current.to_s,
    data: execution_state_data  # 子类定义的状态数据
  }
  
  # 存储到数据库（JSON 类型）
  ActiveRecord::Base.connection.execute(
    "INSERT INTO validator_executions (execution_id, state, ...) ..."
  )
end

# Verify 阶段恢复状态
def restore_execution_state
  result = ActiveRecord::Base.connection.execute(
    "SELECT state FROM validator_executions WHERE execution_id = ?"
  )
  state = JSON.parse(result['state'])
  restore_from_state(state['data'])  # 子类实现状态恢复
end
```

**优势**:
- ✅ 跨请求状态传递
- ✅ 支持分布式部署（多服务器共享数据库）
- ✅ 可追溯历史执行记录

---

## 架构设计

### 文件结构

```
app/validators/
├── base_validator.rb              # 基础验证器类
├── book_flight_validator.rb       # 机票预订验证器
├── search_cheapest_flight_validator.rb  # 低价搜索验证器
└── support/
    └── data_packs/
        └── v1/
            ├── flights.rb         # 航班数据包 v1
            ├── hotels.rb          # 酒店数据包 v1
            ├── cars.rb            # 租车数据包 v1
            ├── bus_tickets.rb     # 汽车票数据包 v1
            ├── hotel_packages.rb  # 酒店套餐数据包 v1
            ├── tour_group_products.rb  # 跟团游数据包 v1
            ├── deep_travel.rb     # 深度旅行数据包 v1
            ├── internet_services.rb  # 境外上网数据包 v1
            ├── abroad_tickets.rb  # 境外交通数据包 v1
            └── abroad_shopping.rb # 境外购物数据包 v1

bin/verify                         # 命令行工具

db/migrate/
└── 20260113090014_create_validator_executions.rb  # 状态存储表
```

### 核心类关系

```
BaseValidator (抽象基类)
├── include RSpec::Matchers
├── Checkpoint 管理
│   ├── ensure_checkpoint()
│   ├── rollback_to_checkpoint()
│   └── reset_test_data_only()
├── 数据包加载
│   └── load_data_pack()
├── 状态持久化
│   ├── save_execution_state()
│   ├── restore_execution_state()
│   └── cleanup_execution_state()
└── 验证流程
    ├── execute_prepare()
    ├── execute_verify()
    ├── prepare() [抽象方法]
    └── verify() [抽象方法]

BookFlightValidator (具体验证器)
├── 继承 BaseValidator
├── validator_id = 'book_flight_sz_to_bj'
├── data_pack_version = 'v1/flights'
├── prepare() 实现
│   ├── 设置任务参数（日期、城市）
│   ├── 计算最低价
│   └── 返回任务信息
├── verify() 实现
│   ├── add_assertion("订单已创建", weight: 20)
│   ├── add_assertion("出发城市正确", weight: 10)
│   ├── add_assertion("目的城市正确", weight: 10)
│   ├── add_assertion("出发日期正确", weight: 20)
│   └── add_assertion("选择了最低价航班", weight: 40)
└── 状态管理
    ├── execution_state_data()
    └── restore_from_state()
```

---

## 核心亮点

### 亮点 1: Checkpoint 智能检测

**传统做法**:
```ruby
# 每次都清空数据库并重新加载 seeds（慢！）
def prepare
  Rails.application.load_seed  # 耗时操作
  load_data_pack
end
```

**新设计**:
```ruby
def ensure_checkpoint
  # 检查是否已经有 checkpoint（City + Flight 都有数据）
  if City.count == 0 || Flight.count == 0
    puts "数据库不在 checkpoint 状态，正在加载 seeds..."
    load Rails.root.join('db/seeds.rb')
    puts "✓ Checkpoint 已创建"
  else
    puts "数据库已在 checkpoint 状态，跳过 seeds 加载"
  end
end
```

**性能提升**: 重复运行时跳过 seeds 加载，节省 5-10 秒

### 亮点 2: 分层数据清理

**核心设计**: 区分三类数据

1. **基础数据（Checkpoint）**: City、Destination（始终保留）
2. **测试数据**: Flight、Hotel、Train 等（验证器加载，验证后清空）
3. **订单数据**: Booking、HotelBooking 等（用户操作产生，验证后清空）

```ruby
# 准备阶段：只清空测试数据
def reset_test_data_only
  [Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket].each do |model|
    model.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
  end
  # 保留 City、Destination（属于 checkpoint）
  # 保留订单（会在验证后统一清理）
end

# 验证后：清空测试数据和订单，恢复 checkpoint
def rollback_to_checkpoint
  # 清空订单 + 测试数据
  [
    Booking, HotelBooking, TrainBooking, CarOrder, BusTicketOrder,  # 订单
    Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket    # 测试数据
  ].each { |model| model.delete_all }
  
  # 重新加载 seeds（恢复 checkpoint）
  load Rails.root.join('db/seeds.rb')
end
```

### 亮点 3: 版本化数据包

**设计思路**: 数据包支持语义化版本管理

```ruby
class BookFlightValidator < BaseValidator
  self.data_pack_version = 'v1/flights'  # 版本化路径
  # 加载: app/validators/support/data_packs/v1/flights.rb
end
```

**数据包示例** (`v1/flights.rb`):
```ruby
# 动态日期设置（始终有效）
base_date = Date.current + 3.days

# 数据结构化定义
[
  {
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_datetime.change(hour: 8, min: 0),
    price: 680.0,
    flight_date: base_date
  },
  # ...
].each { |attrs| Flight.create!(attrs) }

puts "✓ flights_v1 数据包加载完成（6个航班）"
```

**优势**:
- ✅ 版本隔离：v1/v2 数据包共存
- ✅ 动态日期：使用 `Date.current + N.days` 确保数据始终可选
- ✅ 易于维护：每个业务模块独立数据包

### 亮点 4: RSpec 风格 DSL

**核心方法**: `add_assertion`

```ruby
def verify
  # 断言语法清晰易读
  add_assertion "订单已创建", weight: 20 do
    @booking = Booking.order(created_at: :desc).first
    expect(@booking).not_to be_nil, "未找到任何订单记录"
  end
  
  add_assertion "选择了最低价航班", weight: 40 do
    lowest_price = Flight.where(...).minimum(:price)
    expect(@booking.flight.price).to eq(lowest_price),
      "未选择最低价航班。最低价: #{lowest_price}, 实际: #{@booking.flight.price}"
  end
end
```

**自动计分**:
```ruby
def add_assertion(name, weight:)
  assertion = { name: name, weight: weight, passed: false, error: nil }
  
  begin
    yield  # 执行断言块
    assertion[:passed] = true
    @score += weight  # 通过加分
  rescue RSpec::Expectations::ExpectationNotMetError => e
    assertion[:passed] = false
    assertion[:error] = e.message
    @errors << "#{name} 失败: #{e.message}"
  end
  
  @assertions << assertion
end
```

**输出示例**:
```
📋 断言详情:

  ✓ 订单已创建 (权重: 20) - 通过
  ✓ 出发城市正确 (权重: 10) - 通过
  ✓ 目的城市正确 (权重: 10) - 通过
  ✓ 出发日期正确 (权重: 20) - 通过
  ✗ 选择了最低价航班 (权重: 40) - 失败
     错误: 未选择最低价航班。最低价: 550, 实际: 680

🎯 得分: 60/100
```

### 亮点 5: 交互式 CLI

**核心体验**: `bin/verify run <validator_id>`

```bash
# 步骤 1: 列出所有验证器
$ bin/verify list

📋 可用的验证器 (共 2 个):

  🔹 ID: book_flight_sz_to_bj
     标题: 预订深圳到北京的低价机票
     描述: 在今天的航班中找到价格最低的机票并完成预订
     数据包: v1/flights
     超时: 300秒

# 步骤 2: 运行验证器
$ bin/verify run book_flight_sz_to_bj

============================================================
🚀 开始执行验证: 预订深圳到北京的低价机票
============================================================

📦 准备阶段: 加载数据包...

ℹ️  数据库已在 checkpoint 状态，跳过 seeds 加载
正在加载 flights_v1 数据包...
✓ flights_v1 数据包加载完成（6个航班）

✅ 准备完成！任务信息：
{
  "task": "请预订一张深圳到北京的低价机票",
  "departure_city": "深圳市",
  "destination_city": "北京市",
  "date": "2026-01-16",
  "hint": "系统中有多个航班可选，请选择价格最低的航班",
  "available_flights_count": 4,
  "lowest_price": 550.0
}

------------------------------------------------------------
⏸️  请手动完成以下操作:
   1. 启动项目: bin/dev
   2. 在浏览器中完成任务
   3. 完成后按回车继续验证...
------------------------------------------------------------

[用户按回车后...]

🔍 验证阶段: 检查结果...

ℹ️  回滚到 checkpoint 状态...
✓ 已回滚到 checkpoint 状态

============================================================
📊 验证结果
============================================================

✅ 状态: PASSED
🎯 得分: 100/100

📋 断言详情:

  ✓ 订单已创建 (权重: 20) - 通过
  ✓ 出发城市正确 (权重: 10) - 通过
  ✓ 目的城市正确 (权重: 10) - 通过
  ✓ 出发日期正确 (权重: 20) - 通过
  ✓ 选择了最低价航班 (权重: 40) - 通过

🏆 优秀！完美完成任务！
============================================================
```

### 亮点 6: 自动回滚机制

**设计原则**: Fail-Safe，验证后始终恢复到 checkpoint

```ruby
def execute_verify
  result = { ... }
  
  begin
    restore_execution_state
    verify
    result[:status] = @errors.empty? ? 'passed' : 'failed'
  rescue StandardError => e
    result[:status] = 'error'
  end
  
  cleanup_execution_state
  
  # 核心：无论成功/失败/异常，都回滚到 checkpoint
  rollback_to_checkpoint
  
  result
end
```

**保证**:
- ✅ 验证失败时自动清理
- ✅ 验证异常时自动清理
- ✅ 下次运行时数据库状态一致

---

## 技术实现

### 1. 数据库 Schema

```ruby
# db/migrate/20260113090014_create_validator_executions.rb
create_table :validator_executions do |t|
  t.string :execution_id, null: false, index: { unique: true }
  t.json :state, null: false
  t.timestamps
end
```

**字段说明**:
- `execution_id`: UUID，唯一标识一次执行
- `state`: JSON 类型，存储验证器状态
  ```json
  {
    "validator_class": "BookFlightValidator",
    "timestamp": "2026-01-13 14:30:00",
    "data": {
      "target_date": "2026-01-16",
      "origin": "深圳市",
      "destination": "北京市",
      "lowest_price": 550.0
    }
  }
  ```

### 2. 验证流程时序图

```
┌──────┐        ┌──────────┐        ┌──────────┐
│ CLI  │        │Validator │        │ Database │
└──┬───┘        └────┬─────┘        └────┬─────┘
   │                 │                   │
   │ run validator   │                   │
   ├────────────────>│                   │
   │                 │                   │
   │                 │ ensure_checkpoint │
   │                 ├──────────────────>│
   │                 │ <check City/Flight>
   │                 │<──────────────────┤
   │                 │                   │
   │                 │ reset_test_data_only
   │                 ├──────────────────>│
   │                 │ <delete Flight/Hotel>
   │                 │<──────────────────┤
   │                 │                   │
   │                 │ load_data_pack    │
   │                 ├──────────────────>│
   │                 │ <insert test data>
   │                 │<──────────────────┤
   │                 │                   │
   │                 │ save_execution_state
   │                 ├──────────────────>│
   │                 │ <insert state>    │
   │                 │<──────────────────┤
   │                 │                   │
   │<────task info───┤                   │
   │                 │                   │
   │ [User operates in browser]          │
   │                 │                   │
   │ press Enter     │                   │
   ├────────────────>│                   │
   │                 │                   │
   │                 │ restore_execution_state
   │                 ├──────────────────>│
   │                 │ <fetch state>     │
   │                 │<──────────────────┤
   │                 │                   │
   │                 │ verify (check DB) │
   │                 ├──────────────────>│
   │                 │ <query orders>    │
   │                 │<──────────────────┤
   │                 │                   │
   │                 │ rollback_to_checkpoint
   │                 ├──────────────────>│
   │                 │ <delete test data>│
   │                 │ <reload seeds>    │
   │                 │<──────────────────┤
   │                 │                   │
   │<────result──────┤                   │
   │                 │                   │
```

### 3. 关键代码片段

#### BaseValidator 核心方法

```ruby
class BaseValidator
  # 准备阶段（数据持久化）
  def execute_prepare
    ensure_checkpoint           # 1. 检查/创建 checkpoint
    reset_test_data_only        # 2. 清空测试表
    load_data_pack              # 3. 加载数据包（持久化！）
    @prepare_result = prepare   # 4. 执行自定义准备
    save_execution_state        # 5. 保存状态
    @prepare_result
  end
  
  # 验证阶段（直接验证现有数据）
  def execute_verify
    result = { ... }
    
    begin
      restore_execution_state   # 1. 恢复状态
      verify                    # 2. 执行验证（不重新加载数据！）
      result[:status] = @errors.empty? ? 'passed' : 'failed'
    rescue StandardError => e
      result[:status] = 'error'
    end
    
    cleanup_execution_state     # 3. 清理状态
    rollback_to_checkpoint      # 4. 回滚到 checkpoint
    
    result
  end
  
  # Checkpoint 检测
  def ensure_checkpoint
    if City.count == 0 || Flight.count == 0
      load Rails.root.join('db/seeds.rb')
    end
  end
  
  # 只清空测试数据
  def reset_test_data_only
    [Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket].each do |model|
      model.delete_all
      ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
    end
  end
  
  # 回滚到 checkpoint
  def rollback_to_checkpoint
    # 清空订单 + 测试数据
    [
      Booking, HotelBooking, TrainBooking, CarOrder, BusTicketOrder,
      Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket
    ].each { |model| model.delete_all }
    
    # 重新加载 seeds
    load Rails.root.join('db/seeds.rb')
  end
end
```

#### 具体验证器实现

```ruby
class BookFlightValidator < BaseValidator
  self.validator_id = 'book_flight_sz_to_bj'
  self.data_pack_version = 'v1/flights'
  
  def prepare
    @target_date = Date.current + 3.days
    @origin = '深圳市'
    @destination = '北京市'
    @lowest_price = Flight.where(...).minimum(:price)
    
    { task: "请预订...", ... }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil
    end
    
    add_assertion "选择了最低价航班", weight: 40 do
      expect(@booking.flight.price).to eq(@lowest_price)
    end
  end
  
  # 状态持久化
  def execution_state_data
    { target_date: @target_date.to_s, origin: @origin, ... }
  end
  
  def restore_from_state(data)
    @target_date = Date.parse(data['target_date'])
    @origin = data['origin']
    ...
  end
end
```

---

## 使用示例

### 示例 1: 创建新验证器

```ruby
# app/validators/book_hotel_validator.rb
class BookHotelValidator < BaseValidator
  self.validator_id = 'book_hotel_shenzhen'
  self.title = '预订深圳酒店'
  self.description = '搜索并预订深圳指定日期的酒店'
  self.data_pack_version = 'v1/hotels'
  self.timeout_seconds = 300
  
  def prepare
    @check_in = Date.current + 1.day
    @check_out = @check_in + 2.days
    @city = '深圳市'
    
    {
      task: "请预订#{@city}的酒店",
      check_in: @check_in.to_s,
      check_out: @check_out.to_s,
      city: @city
    }
  end
  
  def verify
    add_assertion "酒店订单已创建", weight: 30 do
      @booking = HotelBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil
    end
    
    add_assertion "入住日期正确", weight: 20 do
      expect(@booking.check_in_date).to eq(@check_in)
    end
    
    add_assertion "退房日期正确", weight: 20 do
      expect(@booking.check_out_date).to eq(@check_out)
    end
    
    add_assertion "城市正确", weight: 30 do
      expect(@booking.hotel.city).to eq(@city)
    end
  end
  
  private
  
  def execution_state_data
    {
      check_in: @check_in.to_s,
      check_out: @check_out.to_s,
      city: @city
    }
  end
  
  def restore_from_state(data)
    @check_in = Date.parse(data['check_in'])
    @check_out = Date.parse(data['check_out'])
    @city = data['city']
  end
end
```

### 示例 2: 创建数据包

```ruby
# app/validators/support/data_packs/v1/hotels.rb
puts "正在加载 hotels_v1 数据包..."

base_date = Date.current + 1.day

[
  {
    name: "深圳湾大酒店",
    city: "深圳市",
    district: "南山区",
    address: "深圳湾路1号",
    star_rating: 5,
    price: 588.0,
    images: ["https://images.unsplash.com/photo-1566073771259-6a8506099945"]
  },
  # ...
].each do |attrs|
  hotel = Hotel.create!(attrs)
  
  # 创建房型
  hotel.hotel_rooms.create!(
    name: "豪华大床房",
    price: attrs[:price],
    available_rooms: 10
  )
end

puts "✓ hotels_v1 数据包加载完成（5家酒店）"
```

### 示例 3: 运行验证器

```bash
# 方式 1: CLI 交互模式
$ bin/verify run book_hotel_shenzhen

# 方式 2: API 调用（用于 AI Agent）
# Prepare
POST /api/verify/book_hotel_shenzhen/prepare
Response:
{
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "task": {
    "task": "请预订深圳市的酒店",
    "check_in": "2026-01-14",
    "check_out": "2026-01-16",
    "city": "深圳市"
  }
}

# Agent 完成操作...

# Verify
POST /api/verify/550e8400-e29b-41d4-a716-446655440000/result
Response:
{
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "passed",
  "score": 100,
  "assertions": [
    { "name": "酒店订单已创建", "weight": 30, "passed": true },
    { "name": "入住日期正确", "weight": 20, "passed": true },
    { "name": "退房日期正确", "weight": 20, "passed": true },
    { "name": "城市正确", "weight": 30, "passed": true }
  ],
  "errors": []
}
```

---

## 最佳实践

### 1. 验证器设计原则

#### ✅ DO: 明确的任务目标

```ruby
def prepare
  {
    task: "请预订一张深圳到北京的低价机票",  # 明确的任务描述
    hint: "系统中有多个航班可选，请选择价格最低的航班",  # 提示
    departure_city: "深圳市",  # 参数清晰
    destination_city: "北京市",
    date: @target_date.to_s
  }
end
```

#### ❌ DON'T: 模糊的任务

```ruby
def prepare
  { task: "预订机票" }  # 太模糊！
end
```

### 2. 断言设计原则

#### ✅ DO: 分层断言，权重合理

```ruby
def verify
  # 基础断言（必须通过）
  add_assertion "订单已创建", weight: 20 do
    @booking = Booking.order(created_at: :desc).first
    expect(@booking).not_to be_nil
  end
  
  return unless @booking  # 基础断言失败时提前返回
  
  # 正确性断言
  add_assertion "出发城市正确", weight: 10 do
    expect(@booking.flight.departure_city).to eq(@origin)
  end
  
  # 核心断言（高权重）
  add_assertion "选择了最低价航班", weight: 40 do
    expect(@booking.flight.price).to eq(@lowest_price)
  end
end
```

#### ❌ DON'T: 权重不合理

```ruby
def verify
  add_assertion "订单已创建", weight: 80 do  # 权重过高！
    ...
  end
  
  add_assertion "选择了最低价航班", weight: 5 do  # 核心任务权重太低！
    ...
  end
end
```

### 3. 数据包设计原则

#### ✅ DO: 动态日期 + 结构化数据

```ruby
# v1/flights.rb
base_date = Date.current + 3.days  # 动态日期

[
  { departure_city: "深圳市", price: 680.0, flight_date: base_date },
  { departure_city: "深圳市", price: 550.0, flight_date: base_date },  # 最低价
  # ...
].each { |attrs| Flight.create!(attrs) }

puts "✓ 数据包加载完成（6个航班）"
puts "  - 深圳市到北京市: 4个航班，最低价 550元"
```

#### ❌ DON'T: 硬编码日期

```ruby
Flight.create!(
  departure_city: "深圳市",
  flight_date: Date.parse("2026-01-15")  # 硬编码！会过期
)
```

### 4. 状态管理原则

#### ✅ DO: 保存所有验证所需的状态

```ruby
def execution_state_data
  {
    target_date: @target_date.to_s,
    origin: @origin,
    destination: @destination,
    lowest_price: @lowest_price  # 验证时需要用到
  }
end

def restore_from_state(data)
  @target_date = Date.parse(data['target_date'])
  @origin = data['origin']
  @destination = data['destination']
  @lowest_price = data['lowest_price']
end
```

#### ❌ DON'T: 状态不完整

```ruby
def execution_state_data
  { target_date: @target_date.to_s }  # 缺少其他状态！
end

def verify
  # @origin 未恢复，值为 nil！
  expect(@booking.flight.departure_city).to eq(@origin)
end
```

### 5. 错误处理原则

#### ✅ DO: 提供详细的错误信息

```ruby
add_assertion "选择了最低价航班", weight: 40 do
  lowest_price = Flight.where(...).minimum(:price)
  expect(@booking.flight.price).to eq(lowest_price),
    "未选择最低价航班。最低价: #{lowest_price}, 实际选择: #{@booking.flight.price}"
    # 明确的错误信息
end
```

#### ❌ DON'T: 模糊的错误信息

```ruby
add_assertion "选择了最低价航班", weight: 40 do
  expect(@booking.flight.price).to eq(@lowest_price)  # 默认错误信息太简单
end
```

---

## 与传统测试框架对比

| 特性 | 传统测试（RSpec/Minitest） | 验证器系统 |
|------|---------------------------|-----------|
| **数据持久化** | ❌ 事务回滚，数据消失 | ✅ 数据直接提交，始终可用 |
| **Checkpoint 机制** | ❌ 每次重新加载 | ✅ 智能检测，避免重复加载 |
| **交互式验证** | ❌ 不支持 | ✅ CLI 交互模式，等待用户操作 |
| **状态持久化** | ❌ 不支持跨请求 | ✅ 数据库存储，跨请求恢复 |
| **自动计分** | ❌ 手动计算 | ✅ 权重自动计分 |
| **数据包管理** | ❌ fixtures/factories 混乱 | ✅ 版本化数据包 |
| **回滚机制** | ✅ 自动事务回滚 | ✅ 手动 checkpoint 回滚 |

---

## 总结

### 核心创新点

1. **Checkpoint 机制**: 智能数据库状态管理，避免重复加载
2. **数据持久化**: 移除事务包裹，数据真实存在于数据库
3. **状态隔离**: 跨阶段状态持久化，prepare → verify 无缝衔接
4. **版本化数据包**: 灵活的测试数据管理
5. **RSpec 风格 DSL**: 简洁易读的断言语法
6. **自动回滚**: Fail-Safe 设计，始终恢复到 checkpoint

### 适用场景

- ✅ **AI Agent 任务验证**: 验证 AI Agent 完成任务的质量
- ✅ **端到端测试**: 测试完整用户流程（搜索 → 预订 → 支付）
- ✅ **功能验收测试**: 验证新功能是否满足需求
- ✅ **回归测试**: 确保核心功能未被破坏

### 未来扩展

- 🔮 **并行执行**: 支持多个验证器并行运行
- 🔮 **视觉验证**: 集成 Playwright 进行 UI 验证
- 🔮 **性能指标**: 记录任务完成时间、操作步骤数等
- 🔮 **智能提示**: 根据验证结果提供改进建议

---

**相关文档**:
- [CLI 验证指南](docs/CLI_VALIDATION_GUIDE.md)
- [API 验证指南](docs/API_GUIDE.md)
- [项目结构](docs/PROJECT_STRUCTURE.md)
