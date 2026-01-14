# 验证数据包说明

## ⚠️ 重要提示

**验证系统的 Flight 数据完全由 data pack 控制，不使用 `db/seeds/flights.rb`：**

- `BaseValidator#reset_test_tables` 会清空所有 Flight 数据（包括 seed 创建的）
- 然后由各个 data pack（如 `flights_v1.rb`）创建测试数据
- 如果你的数据库包含 seed 的 Flight 数据，请运行 `Flight.delete_all` 清除
- 这确保验证系统使用精确控制的测试数据，不受 seed 数据影响

## 概述

数据包（Data Pack）是验证系统的核心组成部分，提供测试所需的基础数据。每个数据包都是一个独立的 Ruby 脚本文件，用于初始化数据库中的特定数据。

## 设计理念

参考 `db/seeds.rb` 的模块化设计：

1. **模块化**：每个数据包独立管理，便于维护和迭代
2. **版本化**：通过文件名区分版本（如 `flights_v1.rb`, `flights_v2.rb`）
3. **可读性**：使用 Ruby 代码而非 JSON，支持注释和逻辑控制
4. **数据完整性**：在 prepare 阶段自动检查和重置数据

## 目录结构

```
app/validators/support/data_packs/
├── README.md           # 本说明文档
├── flights_v1.rb       # 航班数据包 v1
├── hotels_v1.rb        # 酒店数据包 v1（未来）
└── ...
```

## 数据包规范

### 文件命名

- 格式：`<domain>_v<version>.rb`
- 示例：`flights_v1.rb`, `hotels_v2.rb`
- domain：业务领域（flights, hotels, trains等）
- version：版本号（v1, v2, v3...）

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

# ==================== <数据类型1> ====================
[
  { id: 1, field1: "value1", field2: 100 },
  { id: 2, field1: "value2", field2: 200 }
].each do |attrs|
  Model1.create!(attrs)
end

# ==================== <数据类型2> ====================
[
  { id: 1, field: "value" }
].each do |attrs|
  Model2.create!(attrs)
end

puts "✓ <domain>_v<version> 数据包加载完成（<数量>条记录）"
```

### 最佳实践

1. **明确 ID**：显式指定 ID，便于测试用例引用
2. **添加注释**：解释数据的用途和特征
3. **使用常量**：复杂数据可提取为常量
4. **输出日志**：加载开始和结束时输出日志
5. **数据关联**：注意外键关联，确保数据完整性
6. **动态日期**：使用 `Date.current + N.days` 而不是固定日期，确保数据始终有效

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

## 数据检查点机制

### 工作原理

1. **检查数据库状态**：`database_is_pristine?` 检查验证相关表是否为空
2. **重置数据库**：如非初始状态，`reset_database` 清空验证数据
3. **加载数据包**：执行数据包脚本，创建测试数据

### 保护机制

- **只清理验证数据**：保留 seed 数据（City, Flight基础数据等）
- **事务隔离**：所有操作在事务中进行，回滚时自动清理
- **并发保护**：Mutex 锁确保同一时间只有一个验证运行

## 现有数据包

### flights_v1.rb

**用途**：航班预订验证任务

**数据内容**：
- 深圳→北京：4个航班，价格区间 550-1200 元
- 上海→深圳：2个航班，价格区间 450-520 元（含折扣）

**适用验证**：
- `BookFlightValidator`：预订最低价航班
- `SearchCheapestFlightValidator`：搜索折扣后最低价

## 创建新数据包

### 步骤

1. **创建文件**：`app/validators/support/data_packs/<domain>_v1.rb`
2. **编写数据**：参考上述文件结构
3. **创建验证器**：在 `app/validators/` 中创建对应的验证器类
4. **指定版本**：在验证器中设置 `self.data_pack_version = '<domain>_v1'`
5. **测试验证**：使用 CLI 或 API 测试完整流程

### 示例：创建酒店数据包

```ruby
# app/validators/support/data_packs/hotels_v1.rb
# frozen_string_literal: true

puts "正在加载 hotels_v1 数据包..."

# 酒店数据
[
  {
    id: 1,
    name: "深圳湾大酒店",
    city: "深圳",
    price_per_night: 800.0,
    rating: 4.8,
    available_rooms: 10
  }
].each do |attrs|
  Hotel.create!(attrs)
end

puts "✓ hotels_v1 数据包加载完成"
```

## 版本迭代

当需要修改数据时：

1. **创建新版本**：复制为 `<domain>_v2.rb`
2. **修改数据**：在新文件中进行修改
3. **更新验证器**：修改 `data_pack_version` 为新版本
4. **保留旧版本**：不删除旧文件，保持向后兼容

## 注意事项

1. **不要修改已发布的数据包**：创建新版本而非修改现有版本
2. **确保数据完整性**：外键关联必须正确
3. **必须使用动态日期**：使用 `Date.current + N.days` 而不是 `Date.parse('2024-12-20')`
4. **测试数据真实性**：数据应接近真实场景
5. **文档同步更新**：修改数据包后更新本 README
6. **验证器日期一致性**：验证器的 `prepare` 方法必须使用与数据包相同的日期逻辑

## 相关文件

- `app/validators/base_validator.rb`：数据包加载逻辑
- `app/validators/<task>_validator.rb`：具体验证器
- `db/seeds.rb` 和 `db/seeds/`：系统基础数据（不受验证影响）
