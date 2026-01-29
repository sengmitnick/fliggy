# 验证器文案统一优化总结

## 优化目标

解决验证器中存在的文案冗余问题，统一返回格式，提升代码可维护性。

## 问题分析

### 优化前的问题

每个验证器有4个地方描述任务，存在严重冗余：

```ruby
class V001BookBudgetHotelValidator < BaseValidator
  # 1. 类变量：标题
  self.title = '预订后天入住一晚深圳的经济型酒店'
  
  # 2. 类变量：描述
  self.description = '需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单'
  
  def prepare
    {
      # 3. prepare 返回：task 字段
      task: "请预订后天入住#{@city}的经济型酒店（预算≤#{@budget}元/晚，入住1晚）",
      
      # 4. prepare 返回：hint 字段
      hint: "系统中有多家酒店可选，请选择性价比最高的（综合价格和评分）",
      
      city: @city,
      budget: @budget
    }
  end
end
```

**问题**：
1. ❌ `task` 字段与 `self.title` 内容重复
2. ❌ `hint` 字段与 `self.description` 内容重复
3. ❌ 维护成本高：修改需要同时改多个地方
4. ❌ 容易不一致：4个地方描述可能出现偏差

## 优化方案

### 核心思路

1. **统一数据源**：只在类变量中定义 `title` 和 `description`
2. **自动合并**：`execute_prepare` 自动构造统一格式
3. **过滤冗余**：自动过滤 `task` 和 `hint` 字段
4. **添加日期上下文**：在 `title` 前自动添加当前日期

### 实现代码

```ruby
# app/validators/base_validator.rb

def execute_prepare
  @data_version = SecureRandom.hex(8)
  ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{@data_version}'")
  
  @prepare_result = prepare
  
  # 构造统一的返回格式
  result = {
    title: add_date_context(self.class.title),       # 标题 + 日期上下文
    description: self.class.description              # 描述（来自类变量）
  }
  
  # 合并 prepare 返回的其他字段（排除 task 和 hint）
  if @prepare_result.is_a?(Hash)
    @prepare_result.each do |key, value|
      next if [:task, :hint].include?(key)           # 过滤冗余字段
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

## 优化效果

### 优化后的验证器写法

```ruby
class V001BookBudgetHotelValidator < BaseValidator
  # ✅ 只在类定义处设置标题和描述
  self.title = '预订后天入住一晚深圳的经济型酒店'
  self.description = '需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单'
  
  def prepare
    # ✅ 只返回结构化数据
    {
      city: '深圳',
      budget: 500,
      check_in_date: (Date.current + 2.days).to_s,
      check_out_date: (Date.current + 3.days).to_s,
      nights: 1,
      available_hotels_count: 6
    }
  end
end
```

### API 返回格式

```json
{
  "task": {
    "title": "今天是2026年01月29日。预订后天入住一晚深圳的经济型酒店",
    "description": "需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单",
    "city": "深圳",
    "budget": 500,
    "check_in_date": "2026-01-31",
    "check_out_date": "2026-02-01",
    "nights": 1,
    "available_hotels_count": 6
  },
  "session_id": "xxx",
  "task_id": "v001_book_budget_hotel_validator"
}
```

## 优势对比

| 维度 | 优化前 | 优化后 |
|------|--------|--------|
| **描述位置** | 4处（title + description + task + hint） | 2处（title + description） |
| **日期上下文** | 需要手动在 task 中添加 | 自动添加到 title |
| **维护成本** | 修改需要同步4个地方 | 只需修改类变量 |
| **一致性** | 容易出现不一致 | 自动保证一致 |
| **向后兼容** | N/A | 自动过滤旧字段，无需修改 |

## 字段说明

### 返回字段来源

| 字段 | 来源 | 说明 |
|------|------|------|
| `title` | `self.class.title` + 日期前缀 | 任务标题，带"今天是X年X月X日。"前缀 |
| `description` | `self.class.description` | 任务详细描述，说明如何完成任务 |
| 其他字段 | `prepare` 返回的 Hash | 结构化参数（city, budget 等） |

### 移除的字段

| 字段 | 原因 | 替代方案 |
|------|------|---------|
| `task` | 与 `title` 重复 | 使用 `title`（自动添加日期上下文） |
| `hint` | 与 `description` 重复 | 使用 `description` |

## 向后兼容性

### 自动过滤机制

即使验证器的 `prepare` 方法返回了 `task` 和 `hint` 字段，系统也会自动过滤：

```ruby
# 旧的验证器写法（仍然兼容）
def prepare
  {
    task: "请预订...",      # ❌ 会被过滤，不出现在最终返回中
    hint: "提示信息...",     # ❌ 会被过滤
    city: '深圳',            # ✅ 保留
    budget: 500              # ✅ 保留
  }
end

# 最终返回（自动统一格式）
{
  title: "今天是2026年01月29日。预订后天入住一晚深圳的经济型酒店",
  description: "需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单",
  city: '深圳',
  budget: 500
}
```

## 验证器最佳实践

### ✅ 推荐写法

```ruby
class ValidatorExample < BaseValidator
  # 1. 在类定义处设置标题和描述
  self.title = '任务简短标题'
  self.description = '详细描述如何完成任务'
  
  def prepare
    # 2. 只返回必要的结构化数据
    {
      param1: value1,
      param2: value2,
      date_description: "辅助说明..."  # 可选的补充信息
    }
  end
end
```

### ❌ 不推荐写法

```ruby
class ValidatorExample < BaseValidator
  self.title = '任务简短标题'
  self.description = '详细描述'
  
  def prepare
    {
      task: "请完成...",           # ❌ 冗余，已有 title
      hint: "提示：...",            # ❌ 冗余，已有 description
      instruction: "操作说明...",   # ❌ 冗余，应合并到 description
      param1: value1
    }
  end
end
```

## 测试验证

### 单元测试

```bash
# 测试单个验证器
rails runner "
  validator_class = V001BookBudgetHotelValidator
  instance = validator_class.new(SecureRandom.uuid)
  result = instance.execute_prepare
  puts JSON.pretty_generate(result)
"
```

### API 测试

```bash
# 测试 API 接口
curl -s -X POST 'http://localhost:3000/api/tasks/v001_book_budget_hotel_validator/start' \
  | python3 -m json.tool
```

### 完整验证器测试

```bash
# 运行所有验证器测试
bundle exec rake validator:simulate

# 运行单个验证器
bundle exec rake validator:simulate VALIDATOR=v001_book_budget_hotel_validator
```

## 涉及的文件

### 核心修改

- `app/validators/base_validator.rb` - 实现统一格式和日期上下文

### 文档

- `docs/DATE_CONTEXT_FEATURE.md` - 日期上下文功能详细文档
- `docs/VALIDATOR_TEXT_UNIFICATION.md` - 本文档

### 验证器（可选优化）

所有验证器都可以按照最佳实践优化，但不是必须的（系统会自动过滤）：
- `app/validators/v001_book_budget_hotel_validator.rb`
- `app/validators/v002_book_earliest_train_validator.rb`
- `app/validators/v069_book_shanghai_disney_family_tickets_validator.rb`
- ... 其他所有验证器

## 迁移指南

### 对于新验证器

按照最佳实践编写，只需：
1. 设置 `self.title` 和 `self.description`
2. `prepare` 方法只返回结构化数据
3. 不要返回 `task` 和 `hint` 字段

### 对于现有验证器

**无需修改**！系统会自动：
1. 使用 `self.title` 和 `self.description`
2. 自动过滤 `task` 和 `hint` 字段
3. 自动添加日期上下文

如果需要优化（可选）：
1. 删除 `prepare` 中的 `task` 和 `hint` 字段
2. 确保 `self.title` 和 `self.description` 准确描述任务

## 总结

通过这次优化，我们实现了：

1. ✅ **消除冗余**：从4处描述减少到2处
2. ✅ **统一格式**：所有验证器返回格式统一
3. ✅ **自动日期上下文**：无需手动处理相对日期
4. ✅ **易于维护**：修改只需改类变量
5. ✅ **向后兼容**：现有验证器无需修改
6. ✅ **更好的一致性**：自动保证标题和描述一致

这次优化显著提升了代码质量和可维护性，为后续开发奠定了良好基础。
