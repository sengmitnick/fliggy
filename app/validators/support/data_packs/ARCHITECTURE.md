# 数据包系统架构说明

## 设计理念

数据包系统采用 Ruby seed 文件代替 JSON，实现了模块化、版本化的测试数据管理。

## 核心流程

### 数据加载顺序

```
1. ensure_seed_loaded()
   ↓ 检查 City 表是否有数据
   ↓ 如果为空，加载 db/seeds/cities.rb
   ↓ 确保基础数据存在

2. reset_test_tables()
   ↓ 清空所有测试相关的表（Flight, Booking, Train, Hotel 等）
   ↓ 保留基础数据（City, Administrator 等）
   ↓ 重置 ID 序列

3. load_data_pack()
   ↓ 执行数据包脚本（如 flights_v1.rb）
   ↓ 创建测试数据（如 6 个航班）
```

### 事务隔离机制

#### execute_prepare() 流程

```ruby
# 在事务外执行（持久化）
ensure_seed_loaded()      # 加载 City 等基础数据
reset_test_tables()       # 清空 Flight 等测试表

# 在事务内执行（会回滚）
ActiveRecord::Base.transaction do
  load_data_pack()        # 加载 6 个测试航班
  prepare()               # 执行自定义准备逻辑
  raise ActiveRecord::Rollback  # 回滚
end

save_execution_state()    # 持久化执行状态
```

**结果**：
- City 表有数据（持久化）
- Flight 表为空（事务回滚）
- 执行状态已保存（持久化）

#### execute_verify() 流程

```ruby
# 在事务外执行（持久化）
ensure_seed_loaded()      # 确保 City 数据存在
reset_test_tables()       # 清空 Flight 等测试表

# 在事务内执行（会回滚）
ActiveRecord::Base.transaction do
  restore_execution_state()  # 恢复执行状态
  load_data_pack()          # 重新加载 6 个测试航班
  verify()                  # 执行验证逻辑
  raise ActiveRecord::Rollback  # 回滚
end

cleanup_execution_state()  # 清理执行状态
```

**结果**：
- 验证在 6 个测试航班上执行（事务内可见）
- 验证完成后数据被清除（事务回滚）
- 数据库恢复干净状态

## 数据分类

### 基础数据（永久）
- **City**: 城市数据，从 `db/seeds/cities.rb` 加载
- **Administrator**: 管理员账户
- 这些数据在 `reset_test_tables()` 中**不会被清除**

### 测试数据（临时）
- **Flight, Train, Hotel, Car, BusTicket**: 产品数据
- **Booking, HotelBooking, TrainBooking, etc.**: 订单数据
- 这些数据在 `reset_test_tables()` 中**会被清除**

## 检查点机制

### 为什么需要 reset_test_tables()?

**问题场景**：
```
初始状态: Flight 表有 1658 条 seed 数据
验证器要求: 只需要 6 条特定测试数据
```

**解决方案**：
```ruby
def reset_test_tables
  # 清空所有测试表
  [Booking, Flight, Train, Hotel, ...].each do |model|
    model.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
  end
end
```

**执行时机**：
- 在事务**外**执行，确保清除操作持久化
- 在每次 `execute_prepare()` 和 `execute_verify()` 时调用
- 在 `load_data_pack()` 之前调用

### 为什么需要 ensure_seed_loaded()?

**问题场景**：
```
验证器依赖: Flight 的 departure_city 和 destination_city 必须在 City 表中存在
数据库状态: City 表可能为空（全新数据库）
```

**解决方案**：
```ruby
def ensure_seed_loaded
  if City.count == 0
    load Rails.root.join('db/seeds/cities.rb')
  end
end
```

**执行时机**：
- 在 `reset_test_tables()` 之前执行
- 确保删除 Flight 时不会影响关联约束

## 实际执行示例

### 场景：从 1658 条 seed 航班到 6 条测试航班

```bash
# 初始状态
Flight.count # => 1658 (seed 数据)

# 执行 validator.execute_prepare
# → ensure_seed_loaded(): City 已存在，跳过
# → reset_test_tables(): Flight.delete_all
Flight.count # => 0

# → load_data_pack(): 创建 6 个测试航班（事务内）
Flight.count # => 6 (在事务内可见)

# → 事务回滚
Flight.count # => 0 (事务外查询)

# 执行 validator.execute_verify
# → ensure_seed_loaded(): City 已存在，跳过
# → reset_test_tables(): Flight.delete_all (已经是 0，无影响)
# → load_data_pack(): 重新创建 6 个测试航班（事务内）
# → verify(): 在 6 个航班上执行验证
# → 事务回滚
Flight.count # => 0 (验证完成，数据库恢复干净)
```

## 设计优势

### 1. 数据隔离
- 基础数据（City）和测试数据（Flight）分离
- 验证器只修改测试数据，不影响基础数据

### 2. 可重复性
- 每次验证前清空测试表
- 每次验证后回滚事务
- 确保验证器可重复执行

### 3. 性能优化
- 只在必要时加载 seed 数据
- 使用 `delete_all` 而不是 `destroy_all`（跳过回调）
- 重置 ID 序列避免冲突

### 4. 可维护性
- Ruby 代码比 JSON 更易维护
- 模块化设计，每个域独立文件
- 版本化命名（flights_v1, flights_v2）

## 常见问题

### Q: 为什么 prepare 后 Flight.count = 0?
A: 这是**正确的行为**。prepare 在事务内加载数据，事务回滚后数据消失。verify 会重新加载数据。

### Q: 为什么需要在事务外清除数据？
A: 因为事务回滚会恢复数据。如果在事务内清除 seed 数据（1658 条），回滚后这些数据会恢复，导致验证器看到错误的数据量。

### Q: 如何添加新的数据包？
A: 在 `app/validators/support/data_packs/` 下创建新文件，如 `hotels_v1.rb`，然后在验证器中设置 `self.data_pack_version = 'hotels_v1'`。

### Q: 能否在一个验证器中使用多个数据包？
A: 可以。在 `load_data_pack` 方法中调用多个数据包脚本即可。

## 未来扩展

### 计划功能
1. **数据包依赖管理**: 自动加载依赖的数据包
2. **数据包版本迁移**: 提供升级路径
3. **数据包测试工具**: 验证数据包完整性
4. **性能监控**: 记录数据加载时间

### 示例：多数据包支持

```ruby
class ComplexValidator < BaseValidator
  self.data_pack_version = 'complex_v1'
  
  def load_data_pack
    load Rails.root.join('app/validators/support/data_packs/flights_v1.rb')
    load Rails.root.join('app/validators/support/data_packs/hotels_v1.rb')
    load Rails.root.join('app/validators/support/data_packs/trains_v1.rb')
  end
end
```
