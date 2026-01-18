# 动态日期修复总结

## 问题描述

用户反馈：执行 `bin/verify` 时，任务信息中显示的日期是 **2024-12-20**（固定的历史日期），导致系统无法选择这些航班（系统只允许选择今天及之后的日期）。

### 问题原因

数据包和验证器使用了**硬编码的固定日期**：

1. **数据包** (`flights_v1.rb`)：使用 `Date.parse("2024-12-20")`
2. **验证器** (`book_flight_validator.rb` & `search_cheapest_flight_validator.rb`)：使用 `Date.parse('2024-12-20')`

当时间推移后，这些日期变成历史日期，无法在前端日期选择器中使用。

## 解决方案

### 核心思路

使用**动态日期**（相对于当前日期）代替固定日期：

```ruby
# ❌ 错误：固定日期（会过期）
flight_date = Date.parse("2024-12-20")

# ✅ 正确：动态日期（始终有效）
flight_date = Date.current + 3.days
```

### 具体修改

#### 1. 数据包 (flights_v1.rb)

**修改前：**
```ruby
departure_time: Time.zone.parse("2024-12-20 08:00:00"),
arrival_time: Time.zone.parse("2024-12-20 11:30:00"),
flight_date: Date.parse("2024-12-20")
```

**修改后：**
```ruby
# 使用动态日期
base_date = Date.current + 3.days
base_datetime = base_date.to_time.in_time_zone

departure_time: base_datetime.change(hour: 8, min: 0),
arrival_time: base_datetime.change(hour: 11, min: 30),
flight_date: base_date
```

#### 2. 验证器 (book_flight_validator.rb)

**修改前：**
```ruby
def prepare
  @target_date = Date.parse('2024-12-20')
  # ...
end
```

**修改后：**
```ruby
def prepare
  # 使用动态日期，与数据包保持一致
  @target_date = Date.current + 3.days
  # ...
end
```

#### 3. 验证器 (search_cheapest_flight_validator.rb)

同样的修改：
```ruby
def prepare
  @target_date = Date.current + 3.days
  # ...
end
```

## 验证结果

### 修改前
```json
{
  "task": "请预订一张深圳到北京的低价机票",
  "date": "2024-12-20",  // ❌ 历史日期，无法选择
  "available_flights_count": 0
}
```

### 修改后
```json
{
  "task": "请预订一张深圳到北京的低价机票",
  "date": "2026-01-16",  // ✅ 未来日期（今天+3天），可以选择
  "available_flights_count": 4,
  "lowest_price": "550.0"
}
```

## 关键设计原则

### 1. 日期偏移量选择

选择 **+3天** 的原因：
- ✅ 确保日期在未来（今天、明天都可能有边界问题）
- ✅ 给用户足够的操作时间
- ✅ 符合真实场景（提前3天预订）

### 2. 数据包与验证器一致性

**关键规则**：数据包和验证器必须使用**完全相同**的日期计算逻辑。

```ruby
# 数据包
base_date = Date.current + 3.days  # ← 必须一致

# 验证器
@target_date = Date.current + 3.days  # ← 必须一致
```

否则会导致：
- 数据包创建 1月16日 的航班
- 验证器查询 1月20日 的航班
- 结果：找不到航班，验证失败

### 3. 使用 Date.current 而非 Date.today

```ruby
# ✅ 推荐：使用 Date.current（考虑时区）
Date.current + 3.days

# ⚠️ 避免：使用 Date.today（不考虑时区）
Date.today + 3.days
```

`Date.current` 会根据 Rails 配置的时区返回正确的日期。

## 测试确认

### 测试1：数据包加载
```bash
rails runner "..."
# 输出：
# 今天: 2026-01-13
# 航班日期: 2026-01-16 (今天+3天)
# ✓ flights_v1 数据包加载完成（6个航班）
# 有效航班数: 6/6 ✅
```

### 测试2：验证器准备阶段
```bash
bin/verify show book_flight_sz_to_bj
# 输出：
# Date: 2026-01-16 ✅
# Available flights: 4
# Lowest price: 550.0
```

### 测试3：完整验证流程
```bash
rails runner "validator = BookFlightValidator.new; info = validator.execute_prepare; puts info[:date]"
# 输出：2026-01-16 ✅
```

## 最佳实践总结

### ✅ DO（应该做的）

1. **使用动态日期**
   ```ruby
   Date.current + N.days
   ```

2. **保持一致性**
   - 数据包和验证器使用相同的日期逻辑
   - 统一使用 `Date.current`

3. **合理选择偏移量**
   - 预订类业务：+3天 ~ +7天
   - 查询类业务：今天 ~ +30天

4. **输出日志**
   ```ruby
   puts "  航班日期: #{base_date} (今天+3天)"
   ```

### ❌ DON'T（不应该做的）

1. **避免硬编码日期**
   ```ruby
   # ❌ 绝对不要这样做
   Date.parse("2024-12-20")
   Time.zone.parse("2024-12-20 08:00:00")
   ```

2. **避免不同步的日期逻辑**
   ```ruby
   # ❌ 数据包用 +3天，验证器用 +5天 → 数据不匹配
   ```

3. **避免使用 Date.today**
   ```ruby
   # ⚠️ 可能导致时区问题
   Date.today + 3.days
   ```

## 扩展应用

这个动态日期模式适用于所有时间相关的验证器：

- **航班预订**：今天+3天
- **酒店预订**：今天+7天（给更多选择空间）
- **火车票预订**：今天+1天（火车票通常提前较短）
- **景点门票**：今天+1天（当天或次日游玩）

示例：
```ruby
# 酒店数据包
check_in_date = Date.current + 7.days
check_out_date = check_in_date + 2.days

# 火车票数据包
departure_date = Date.current + 1.day

# 景点门票数据包
visit_date = Date.current + 1.day
```

## 相关文件

- `app/validators/support/data_packs/flights_v1.rb` - 数据包（已修改）
- `app/validators/book_flight_validator.rb` - 验证器1（已修改）
- `app/validators/search_cheapest_flight_validator.rb` - 验证器2（已修改）
- `app/validators/support/data_packs/README.md` - 文档（已更新）

## 总结

通过将固定日期改为动态日期（`Date.current + 3.days`），成功解决了日期过期问题。现在验证系统可以长期稳定运行，不需要手动更新日期。这是一个**一次修复，永久有效**的方案。
