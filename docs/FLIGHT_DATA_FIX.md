# 航班数据包和验证器修复

## 问题描述

原有实现存在以下问题：

### 1. 数据包日期问题
- **原实现**：使用 `Date.current + 3.days` 生成单天的航班数据
- **问题**：数据太少，不够灵活，不适合多场景测试
- **影响**：验证器只能测试固定日期，无法测试未来7天内的任意日期

### 2. 验证器任务描述不明确
- **原实现**：
  - BookFlightValidator: "在今天的航班中找到价格最低的机票"
  - SearchCheapestFlightValidator: "搜索上海到深圳的所有航班"
- **问题**：没有明确指定日期范围，Agent 不知道应该搜索哪一天
- **影响**：Agent 可能搜索错误的日期，导致验证失败

### 3. 数据生成过于复杂
- **原方案**：曾尝试 `Flight.generate_for_route` 生成大量数据
- **问题**：生成数据太多，后续处理复杂，最终放弃
- **影响**：增加系统负担，降低测试效率

## 解决方案

### 1. 数据包改进：生成未来7天的航班数据

**修改文件**: `app/validators/support/data_packs/v1/flights.rb`

#### 日期范围调整
```ruby
# 原实现
base_date = Date.current + 3.days
base_datetime = base_date.to_time.in_time_zone

# 新实现
start_date = Date.current + 1.day  # 从明天开始
end_date = start_date + 6.days     # 到未来第7天
```

#### 数据生成逻辑
- **深圳→北京**：每天4个航班，最低价 ¥550
- **上海→深圳**：每天2个航班，最低价 ¥450（考虑折扣后）
- **总航班数**：7天 × 6个/天 = 42个航班

#### 航班号唯一性
```ruby
# 使用日期偏移生成唯一航班号
day_suffix = (date - Date.current).to_i
flight_number: "CA#{1234 + day_suffix}"  # CA1235, CA1236, ...
```

#### 批量插入优化
```ruby
# 一次性插入所有航班，提高性能
Flight.insert_all(all_flights)
Flight.where(data_version: 0).find_each(&:generate_offers)
```

### 2. 验证器改进：明确指定"后天"

#### BookFlightValidator 修改
```ruby
# 原实现
self.description = '在今天的航班中找到价格最低的机票并完成预订'
@target_date = Date.current + 3.days

# 新实现
self.description = '在后天的航班中找到价格最低的机票并完成预订'
@target_date = Date.current + 2.days  # 后天

# 任务描述
task: "请预订一张后天从深圳到北京的低价机票"
date_description: "后天（2026年01月21日）"
```

#### SearchCheapestFlightValidator 修改
```ruby
# 原实现
self.description = '搜索上海到深圳的所有航班，找出价格最便宜的并完成预订（考虑折扣）'
@target_date = Date.current + 3.days

# 新实现
self.description = '搜索后天上海到深圳的所有航班，找出价格最便宜的并完成预订（考虑折扣）'
@target_date = Date.current + 2.days  # 后天

# 任务描述
task: "请搜索后天从上海市到深圳市的所有航班，找出最便宜的并预订"
date_description: "后天（2026年01月21日）"
```

## 验证结果

### 测试命令
```bash
# 加载数据包
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/base.rb')"
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/demo_user.rb')"
rails runner "load Rails.root.join('app/validators/support/data_packs/v1/flights.rb')"

# 运行测试
rails runner tmp/test_validators.rb
```

### 测试结果
```
✓ BookFlightValidator: 100/100分
  - 订单已创建 (20分)
  - 出发城市正确 (10分)
  - 目的城市正确 (10分)
  - 出发日期正确 (20分)
  - 选择了最低价航班 (40分)

✓ SearchCheapestFlightValidator: 100/100分
  - 订单已创建 (20分)
  - 航线正确 (10分)
  - 出发日期正确 (10分)
  - 选择了最便宜的航班（考虑折扣）(30分)
  - 订单总价准确 (30分)
```

### 数据统计
```
总航班数: 48 (包含旧数据)
深圳→北京: 28个航班 (7天 × 4个/天)
上海→深圳: 14个航班 (7天 × 2个/天)
日期范围: 2026-01-20 至 2026-01-26 (共7天)
```

## 优势总结

### 1. 数据量适中
- ✅ 未来7天覆盖，满足各种测试场景
- ✅ 每天6个航班，数据量可控
- ✅ 避免过度生成导致性能问题

### 2. 任务描述清晰
- ✅ 明确指定"后天"，避免日期歧义
- ✅ 提供格式化日期（如"2026年01月21日"）
- ✅ Agent 知道应该搜索哪一天的航班

### 3. 易于维护
- ✅ 使用循环生成，代码简洁
- ✅ 航班号自动递增，避免重复
- ✅ 批量插入，性能优化

### 4. 灵活可扩展
- ✅ 可轻松调整日期范围（修改 `start_date` 和 `end_date`）
- ✅ 可调整每天航班数量
- ✅ 可添加更多航线

## 相关文件

- `app/validators/support/data_packs/v1/flights.rb` - 航班数据包
- `app/validators/book_flight_validator.rb` - 预订低价机票验证器
- `app/validators/search_cheapest_flight_validator.rb` - 搜索最便宜航班验证器
- `tmp/test_validators.rb` - 测试脚本（可删除）

## 注意事项

1. **日期自动更新**：数据包使用 `Date.current + N.days`，每次运行时自动计算，无需手动维护
2. **数据版本隔离**：验证器使用 `data_version=0` 查询基线数据，确保测试数据隔离
3. **后天为最佳选择**：
   - 明天（+1天）：可能太紧急，不适合演示
   - 后天（+2天）：合理的预订时间，符合真实场景
   - 3天后及以后：可用于其他测试场景

## 未来优化建议

1. 可以为不同日期设置不同价格策略（如周末价格上涨）
2. 可以添加更多航线组合
3. 可以根据验证器需求动态生成数据（而非预生成所有7天）
