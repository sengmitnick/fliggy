# 日期上下文功能

## 功能概述

为了帮助 LLM 正确理解题目中的相对日期（"明天"、"后天"等），系统会自动在任务标题（`title`）前添加当前日期信息，并统一返回格式。

## 实现位置

- **文件**: `app/validators/base_validator.rb`
- **方法**: `add_date_context(title)`、`execute_prepare`
- **调用时机**: `execute_prepare` 方法中，构造统一返回格式时

## 工作原理

### 1. 统一返回格式

系统会在 `execute_prepare` 中构造统一的返回格式：

```ruby
def execute_prepare
  # ...
  @prepare_result = prepare
  
  # 构造统一的返回格式
  result = {
    title: add_date_context(self.class.title),
    description: self.class.description
  }
  
  # 合并 prepare 返回的其他字段（排除 task 和 hint）
  if @prepare_result.is_a?(Hash)
    @prepare_result.each do |key, value|
      next if [:task, :hint].include?(key)
      result[key] = value
    end
  end
  
  result
end
```

### 2. 添加日期前缀

```ruby
def add_date_context(title)
  current_date = Date.current
  date_str = current_date.strftime('%Y年%m月%d日')
  "今天是#{date_str}。#{title}"
end
```

### 3. 字段说明

| 字段 | 来源 | 说明 |
|------|------|------|
| `title` | `self.class.title` + 日期上下文 | 任务标题，带日期前缀 |
| `description` | `self.class.description` | 任务详细描述 |
| 其他字段 | `prepare` 方法返回值 | 结构化数据（city, budget 等） |

**移除的字段**：
- ❌ `task`：已统一到 `title`
- ❌ `hint`：已统一到 `description`

## 示例效果

### 验证器定义

```ruby
class V001BookBudgetHotelValidator < BaseValidator
  self.title = '预订后天入住一晚深圳的经济型酒店'
  self.description = '需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单'
  
  def prepare
    {
      city: '深圳',
      budget: 500,
      check_in_date: (Date.current + 2.days).to_s,
      nights: 1
    }
  end
end
```

### API 返回结果

```json
{
  "task": {
    "title": "今天是2026年01月29日。预订后天入住一晚深圳的经济型酒店",
    "description": "需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单",
    "city": "深圳",
    "budget": 500,
    "check_in_date": "2026-01-31",
    "nights": 1
  },
  "session_id": "xxx",
  "task_id": "v001_book_budget_hotel_validator"
}
```

## 优势

### 1. 消除冗余

**之前**：
- `self.title` = "预订后天入住一晚深圳的经济型酒店"
- `self.description` = "需要在系统中搜索深圳的酒店..."
- `prepare[:task]` = "请预订后天入住深圳的经济型酒店..."
- `prepare[:hint]` = "系统中有多家酒店可选..."

**现在**：
- `title` = "今天是2026年01月29日。" + `self.title`
- `description` = `self.description`
- 其他字段 = `prepare` 返回的结构化数据

### 2. 统一管理

- 任务标题和描述在类定义处统一维护
- 日期上下文自动添加，无需每个验证器单独处理
- 验证器的 `prepare` 方法只返回结构化数据

### 3. 易于维护

修改验证器只需：
1. 修改类变量 `self.title` 和 `self.description`
2. `prepare` 方法返回必要的结构化数据即可

## 使用场景

### 1. 相对日期描述

当任务标题包含相对日期时，日期上下文尤为重要：

**示例 1：明天**
```ruby
class V002BookEarliestTrainValidator < BaseValidator
  self.title = '预订明天上海到杭州最早的高铁（二等座）'
  # ...
end
```

返回：
```json
{
  "title": "今天是2026年01月29日。预订明天上海到杭州最早的高铁（二等座）"
}
```

**示例 2：后天**
```ruby
class V069BookShanghaiDisneyFamilyTicketsValidator < BaseValidator
  self.title = '预订后天上海迪士尼家庭套餐（2成人+1儿童，最便宜）'
  # ...
end
```

返回：
```json
{
  "title": "今天是2026年01月29日。预订后天上海迪士尼家庭套餐（2成人+1儿童，最便宜）"
}
```

## API 接口

### GET /api/tasks

返回所有验证器的元信息（不包含日期上下文，因为未执行 `prepare`）

### POST /api/tasks/:id/start

创建训练会话，返回带日期上下文的任务信息：

**请求**:
```bash
curl -X POST 'http://localhost:3000/api/tasks/v002_book_earliest_train_validator/start'
```

**响应**:
```json
{
  "task": {
    "title": "今天是2026年01月29日。预订明天上海到杭州最早的高铁（二等座）",
    "description": "在明天的车次中找到发车时间最早的高铁并完成预订，优先选择二等座",
    "origin": "上海",
    "destination": "杭州",
    "target_date": "2026-01-30",
    "date_description": "明天（2026年01月30日）",
    "seat_class": "二等座"
  },
  "session_id": "abc123",
  "task_id": "v002_book_earliest_train_validator"
}
```

## 实现细节

### 1. BaseValidator 修改

```ruby
# app/validators/base_validator.rb

def execute_prepare
  @data_version = SecureRandom.hex(8)
  ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{@data_version}'")
  
  @prepare_result = prepare
  
  # ✅ 构造统一的返回格式
  result = {
    title: add_date_context(self.class.title),
    description: self.class.description
  }
  
  # ✅ 合并 prepare 返回的其他字段（排除 task 和 hint）
  if @prepare_result.is_a?(Hash)
    @prepare_result.each do |key, value|
      next if [:task, :hint].include?(key)
      result[key] = value
    end
  end
  
  save_execution_state
  result
end

private

def add_date_context(title)
  current_date = Date.current
  date_str = current_date.strftime('%Y年%m月%d日')
  "今天是#{date_str}。#{title}"
end
```

### 2. 验证器最佳实践

**推荐写法**：

```ruby
class V001BookBudgetHotelValidator < BaseValidator
  # ✅ 在类定义处设置标题和描述
  self.title = '预订后天入住一晚深圳的经济型酒店'
  self.description = '需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单'
  
  def prepare
    # ✅ 只返回结构化数据，不要返回 task 和 hint
    {
      city: '深圳',
      budget: 500,
      check_in_date: (Date.current + 2.days).to_s,
      check_out_date: (Date.current + 3.days).to_s,
      nights: 1
    }
  end
end
```

**不推荐写法**（冗余）：

```ruby
# ❌ 不要这样写
def prepare
  {
    task: "请预订后天入住深圳的经济型酒店...",  # ❌ 冗余，已有 self.title
    hint: "系统中有多家酒店可选...",            # ❌ 冗余，已有 self.description
    city: '深圳',
    budget: 500
  }
end
```

### 3. 兼容性

- ✅ **自动过滤**：即使验证器返回了 `task` 和 `hint` 字段，系统也会自动过滤
- ✅ **向后兼容**：现有验证器无需修改，系统会自动统一格式
- ✅ **无侵入性**：不影响验证器的验证逻辑

## 测试验证

### 1. 单元测试

```bash
# 测试日期上下文功能
rails runner "
  validator_class = V002BookEarliestTrainValidator
  instance = validator_class.new(SecureRandom.uuid)
  result = instance.execute_prepare
  puts result[:task]
"
# 输出: 今天是2026年01月29日。请预订一张明天从上海到杭州最早的高铁票（二等座）
```

### 2. API 测试

```bash
# 测试 API 接口
curl -s -X POST 'http://localhost:3000/api/tasks/v069_book_shanghai_disney_family_tickets_validator/start' \
  | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['task']['task'])"

# 输出: 今天是2026年01月29日。请为一家三口（2成人+1儿童）预订后天（2026年01月31日）上海迪士尼乐园的门票，选择最优惠的供应商组合
```

### 3. 完整验证器测试

```bash
# 运行单个验证器测试
bundle exec rake validator:simulate VALIDATOR=v002_book_earliest_train_validator

# 运行所有验证器测试
bundle exec rake validator:simulate
```

## 涉及的验证器

以下验证器使用相对日期描述，将直接受益于日期上下文功能：

### 使用"明天"的验证器

- `v002_book_earliest_train_validator` - 预订明天上海到杭州最早的高铁
- `v042_book_bus_guangzhou_shenzhen_validator` - 预订明天广州到深圳汽车票
- `v044_book_bus_beijing_tianjin_validator` - 预订明天北京到天津最早汽车票
- `v084_book_airport_dropoff_service_validator` - 明天送机服务
- `v086_book_train_station_dropoff_validator` - 明天早上送到火车站
- `v093_book_local_driver_guide_service_validator` - 明天的导游服务

### 使用"后天"的验证器

- `v001_book_budget_hotel_validator` - 预订后天入住的经济型酒店
- `v069_book_shanghai_disney_family_tickets_validator` - 预订后天上海迪士尼家庭套餐
- `v070_book_beijing_happy_valley_family_tickets_validator` - 预订后天北京欢乐谷
- `v072_book_hangzhou_west_lake_free_ticket_validator` - 预订后天杭州西湖免费票

## 注意事项

### 1. 日期格式

系统使用 `Date.current.strftime('%Y年%m月%d日')` 格式，适合中文场景：
- 格式: `2026年01月29日`
- 语言: 中文
- 位置: 任务描述最前面

### 2. 只影响 task 字段

日期上下文**只添加到** `prepare` 方法返回的 `task` 字段，不影响其他字段（如 `date_description`、`hint` 等）。

### 3. Hash 类型检查

系统会检查 `prepare_result` 是否为 Hash 类型且包含 `task` 字段，确保不会对其他返回格式造成影响。

## 优势

1. **零侵入**: 验证器无需修改，自动获得日期上下文
2. **统一管理**: 日期格式在 `BaseValidator` 中统一维护
3. **准确理解**: LLM 可以准确计算"明天"、"后天"的具体日期
4. **易于维护**: 只需在一个地方修改日期格式

## 未来扩展

### 1. 支持其他语言

可以根据 `I18n.locale` 返回不同语言的日期前缀：

```ruby
def add_date_context(task_description)
  current_date = Date.current
  
  case I18n.locale
  when :en
    date_str = current_date.strftime('%B %d, %Y')
    "Today is #{date_str}. #{task_description}"
  when :zh
    date_str = current_date.strftime('%Y年%m月%d日')
    "今天是#{date_str}。#{task_description}"
  else
    date_str = current_date.to_s
    "Today is #{date_str}. #{task_description}"
  end
end
```

### 2. 可配置格式

可以在 `application.yml` 中配置日期格式：

```yaml
validator:
  date_context_format: '%Y年%m月%d日'
  date_context_prefix: '今天是'
```

### 3. 可选功能

可以添加类变量控制是否启用日期上下文：

```ruby
class BaseValidator
  class_attribute :enable_date_context, default: true
  
  def execute_prepare
    # ...
    if self.class.enable_date_context && @prepare_result.is_a?(Hash) && @prepare_result[:task]
      @prepare_result[:task] = add_date_context(@prepare_result[:task])
    end
    # ...
  end
end

# 特定验证器可以禁用此功能
class SomeValidator < BaseValidator
  self.enable_date_context = false
end
```

## 总结

日期上下文功能通过在任务描述前自动添加当前日期，帮助 LLM 准确理解题目中的相对日期（"明天"、"后天"等），提升了验证器的可用性和准确性。该功能零侵入、易维护，对所有验证器自动生效。
