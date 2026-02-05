# Validator ID Format Check

## 问题背景

### 问题 1: validator_id 格式错误

在 `v299_book_photography_theme_tour_validator.rb` 中发现 `validator_id` 设置为数字 `299`，而不是字符串 `'v299_book_photography_theme_tour_validator'`。这导致 validator 无法正确注册到系统中。

#### 错误示例

```ruby
# ❌ 错误：validator_id 是数字
class V299BookPhotographyThemeTourValidator < BaseValidator
  self.validator_id = 299  # 错误：应该是字符串
end
```

#### 正确示例

```ruby
# ✅ 正确：validator_id 是字符串且与文件名一致
class V299BookPhotographyThemeTourValidator < BaseValidator
  self.validator_id = 'v299_book_photography_theme_tour_validator'
end
```

### 问题 2: task_id UUID 格式错误

在深入分析后，发现 **23 个 validators** 使用了非标准 UUID 格式的 `task_id`，包含了非十六进制字符（如 `g`, `h`, `i`, `j`, `k`）。

#### 错误示例

```ruby
# ❌ 错误：task_id 包含非十六进制字符 'g'
class V125BookEarlyMorningFlightAndBudgetHotelValidator < BaseValidator
  self.task_id = 'd6e7f8g9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'  # 'g' 不是有效的十六进制字符
end
```

#### 正确示例

```ruby
# ✅ 正确：task_id 符合标准 UUID 格式（8-4-4-4-12 十六进制字符）
class V001BookBudgetHotelValidator < BaseValidator
  self.task_id = 'c0342467-8568-4bce-964c-4133c8367e7d'  # 标准 UUID
end

# ✅ 正确：使用 SecureRandom.uuid 生成
class V308BookDivingLessonPhotographyValidator < BaseValidator
  self.task_id = 'f308a001-0001-4001-8001-000000000308'  # 自定义但符合格式
end
```

### 问题 3: simulate 方法未实现

部分 validators 的 `simulate` 方法只抛出 `NotImplementedError`，导致自动测试无法运行。

#### 错误示例

```ruby
# ❌ 错误：simulate 方法未实现
class V001BookBudgetHotelValidator < BaseValidator
  def simulate
    raise NotImplementedError, "Subclass must implement #simulate"
  end
end
```

#### 正确示例

```ruby
# ✅ 正确：完整实现 simulate 方法
class V001BookBudgetHotelValidator < BaseValidator
  def simulate
    # 1. 查找测试用户
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的酒店
    target_hotel = Hotel.where(city: @city, data_version: 0)
                        .where('price <= ?', @budget)
                        .order(rating: :desc)
                        .first
    
    # 3. 创建订单
    HotelBooking.create!(
      hotel_id: target_hotel.id,
      user_id: user.id,
      check_in_date: @check_in_date,
      # ...
    )
  end
end
```

### 问题 4: verify 方法缺少 data_version 过滤

部分 validators 的 `verify` 方法中查询数据时未过滤 `data_version`，导致会话数据混乱。

#### 错误示例

```ruby
# ❌ 错误：查询缺少 data_version 过滤
def verify
  add_assertion "创建了订单", weight: 20 do
    @hotel_booking = HotelBooking.order(created_at: :desc).first  # 缺少 data_version
    expect(@hotel_booking).not_to be_nil
  end
end
```

#### 正确示例

```ruby
# ✅ 正确：查询包含 data_version 过滤
def verify
  add_assertion "创建了订单", weight: 20 do
    @hotel_booking = HotelBooking
      .where(data_version: @data_version)  # 确保会话隔离
      .order(created_at: :desc)
      .first
    expect(@hotel_booking).not_to be_nil
  end
end
```

### 问题 5: 缺少状态保存/恢复方法

`prepare` 方法中设置的实例变量需要通过 `execution_state_data` 和 `restore_from_state` 方法保存和恢复，否则在 `verify` 阶段这些变量会丢失。

#### 错误示例

```ruby
# ❌ 错误：缺少状态管理方法
class V001BookBudgetHotelValidator < BaseValidator
  def prepare
    @city = '深圳'
    @budget = 500
    @check_in_date = Date.today + 2.days
    # ...
  end
  
  def verify
    # @city, @budget, @check_in_date 在这里都是 nil！
    add_assertion "城市正确", weight: 15 do
      expect(@hotel_booking.hotel.city).to eq(@city)  # @city 是 nil！
    end
  end
  
  # 缺少 execution_state_data 和 restore_from_state
end
```

#### 正确示例

```ruby
# ✅ 正确：实现状态管理方法
class V001BookBudgetHotelValidator < BaseValidator
  def prepare
    @city = '深圳'
    @budget = 500
    @check_in_date = Date.today + 2.days
    # ...
  end
  
  def verify
    # @city, @budget, @check_in_date 已通过 restore_from_state 恢复
    add_assertion "城市正确", weight: 15 do
      expect(@hotel_booking.hotel.city).to eq(@city)
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      city: @city,
      budget: @budget,
      check_in_date: @check_in_date.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @city = data['city']
    @budget = data['budget']
    @check_in_date = Date.parse(data['check_in_date'])
  end
end
```

### 检查 3: simulate 方法实现

#### 检查内容

1. **方法存在性**：validator 必须定义 `simulate` 方法
2. **方法完整性**：`simulate` 方法不能只抛出 `NotImplementedError`

#### 实现逻辑

```ruby
if klass.instance_methods(false).include?(:simulate)
  # 读取文件检查是否只是抛出 NotImplementedError
  content = File.read(file)
  simulate_method = content.match(/def\s+simulate.*?^\s*end/m)&.[](0)
  if simulate_method && simulate_method.match?(/raise\s+NotImplementedError/)
    attribute_errors << {
      format_error: "simulate 方法未实现（仅抛出 NotImplementedError）",
      expected: "完整的 simulate 方法实现",
      actual: "raise NotImplementedError"
    }
  end
else
  attribute_errors << {
    format_error: "缺少 simulate 方法",
    expected: "def simulate ... end",
    actual: "未定义"
  }
end
```

### 检查 4: verify 方法中的 data_version 过滤

#### 检查内容

1. **查询过滤**：所有 `Model.where/joins/includes/find_by` 查询必须包含 `data_version` 过滤
2. **会话隔离**：确保不同会话的数据不会互相干扰

#### 实现逻辑

```ruby
content = File.read(file)
verify_method = content.match(/def\s+verify.*?^\s*end/m)&.[](0)
if verify_method
  # 查找所有 Model.where/joins/includes/find_by 查询
  model_queries = verify_method.scan(/\b([A-Z][a-zA-Z]+)\.(where|joins|includes|find_by)/)
  model_queries.each do |model, method|
    next if ['Date', 'File', 'Dir', 'Rails', 'SecureRandom'].include?(model)
    
    # 提取该查询的完整语句
    query_pattern = /#{Regexp.escape(model)}\.#{method}.*?(?=\n\s{0,4}\w|\z)/m
    if query_match = verify_method.match(query_pattern)
      query_text = query_match[0]
      # 检查是否包含 data_version 过滤
      unless query_text.match?(/data_version:?\s*[@:]?\s*@?data_version|where\s*\(.*?data_version/)
        attribute_errors << {
          format_error: "verify 方法中查询缺少 data_version 过滤",
          detail: "#{model}.#{method} 查询未过滤 data_version",
          expected: ".where(data_version: @data_version)",
          actual: query_text.lines.first.strip[0..80]
        }
        break  # 只报告第一个缺失
      end
    end
  end
end
```

### 检查 5: execution_state_data 和 restore_from_state

#### 检查内容

1. **状态保存**：如果 `prepare` 方法设置了实例变量，必须实现 `execution_state_data`
2. **状态恢复**：必须实现 `restore_from_state` 方法来恢复实例变量

#### 实现逻辑

```ruby
prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
if prepare_method
  instance_vars = prepare_method.scan(/@(\w+)\s*=/).flatten.uniq.reject { |v| v == 'data_version' }
  if instance_vars.any?
    has_execution_state_data = content.match?(/def\s+execution_state_data/)
    has_restore_from_state = content.match?(/def\s+restore_from_state/)
    
    if !has_execution_state_data || !has_restore_from_state
      missing_methods = []
      missing_methods << 'execution_state_data' unless has_execution_state_data
      missing_methods << 'restore_from_state' unless has_restore_from_state
      
      attribute_errors << {
        format_error: "缺少状态保存/恢复方法",
        detail: "prepare 方法设置了 #{instance_vars.size} 个实例变量，但缺少 #{missing_methods.join(', ')}",
        expected: "def execution_state_data 和 def restore_from_state",
        actual: "缺少: #{missing_methods.join(', ')}"
      }
    end
  end
end
```

---

## 优化方案

在 `rake validator:simulate` 任务的 **Step 1** 中添加格式检查：

### 检查 1: validator_id 格式

#### 检查内容

1. **类型检查**：`validator_id` 必须是 `String` 类型
2. **格式检查**：`validator_id` 必须与文件名完全一致

#### 实现逻辑

```ruby
if klass.validator_id.present?
  # 检查类型：必须是字符串
  unless klass.validator_id.is_a?(String)
    attribute_errors << {
      format_error: "validator_id 必须是字符串，当前类型: #{klass.validator_id.class}",
      expected: "'#{validator_name}'",
      actual: klass.validator_id.inspect
    }
  else
    # 检查格式：必须与文件名一致
    if klass.validator_id != validator_name
      attribute_errors << {
        format_error: "validator_id 与文件名不一致",
        expected: "'#{validator_name}'",
        actual: "'#{klass.validator_id}'"
      }
    end
  end
end
```

### 检查 2: task_id UUID 格式

#### 检查内容

1. **格式检查**：`task_id` 必须符合标准 UUID 格式（8-4-4-4-12）
2. **字符检查**：只允许十六进制字符（0-9, a-f）

#### UUID 格式规范

标准 UUID 格式：
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
│      │ │  │ │  │ │  │ │          │
8位    4位 4位 4位 12位

只允许字符：0-9, a-f (不区分大小写)
```

#### 实现逻辑

```ruby
if klass.task_id.present?
  uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  unless klass.task_id.match?(uuid_pattern)
    # 检测非法字符
    invalid_chars = klass.task_id.gsub(/[0-9a-f-]/i, '').chars.uniq
    error_detail = if invalid_chars.any?
      "包含非十六进制字符: #{invalid_chars.join(', ')}"
    else
      "格式不符合 UUID 标准（应为 8-4-4-4-12 格式）"
    end
    
    attribute_errors << {
      format_error: "task_id 不符合标准 UUID 格式",
      detail: error_detail,
      expected: "标准 UUID 格式（仅包含 0-9, a-f 字符）",
      actual: "'#{klass.task_id}'"
    }
  end
end
```

---

## 错误报告格式

### validator_id 格式错误

当检测到 `validator_id` 格式错误时：

```
❌ Validator Attribute Errors Found:
----------------------------------------------------------------------

v299_book_photography_theme_tour_validator (V251V300::V299BookPhotographyThemeTourValidator)
  File: app/validators/v251_v300/v299_book_photography_theme_tour_validator.rb
  Format Error: validator_id 必须是字符串，当前类型: Integer
  Expected: 'v299_book_photography_theme_tour_validator'
  Actual: 299
  → validator_id 必须是字符串类型，且与文件名完全一致
----------------------------------------------------------------------

❌ 1 validator(s) have missing or invalid class attributes
Please fix these validators before running simulations
```

### task_id UUID 格式错误

当检测到 `task_id` 格式错误时：

```
❌ Validator Attribute Errors Found:
----------------------------------------------------------------------

v125_book_early_morning_flight_and_budget_hotel_validator (V101V150::V125BookEarlyMorningFlightAndBudgetHotelValidator)
  File: app/validators/v101_v150/v125_book_early_morning_flight_and_budget_hotel_validator.rb
  Format Error: task_id 不符合标准 UUID 格式
  Detail: 包含非十六进制字符: g
  Expected: 标准 UUID 格式（仅包含 0-9, a-f 字符）
  Actual: 'd6e7f8g9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'
  → task_id 必须符合标准 UUID 格式（8-4-4-4-12，仅包含 0-9, a-f 字符）
  → 可使用 SecureRandom.uuid 生成标准 UUID
----------------------------------------------------------------------

❌ 23 validator(s) have missing or invalid class attributes
Please fix these validators before running simulations
```

---

## 修复步骤

### 修复 validator_id 格式错误

**步骤 1**: 修复 v299 validator

```diff
# app/validators/v251_v300/v299_book_photography_theme_tour_validator.rb
module V251V300
  class V299BookPhotographyThemeTourValidator < BaseValidator
-   self.validator_id = 299
+   self.validator_id = 'v299_book_photography_theme_tour_validator'
```

**步骤 2**: 验证修复

```bash
# 运行 validator 模拟测试
rake validator:simulate

# 或运行单个 validator
rake validator:simulate_single[v299_book_photography_theme_tour_validator]
```

**步骤 3**: 测试结果

```
🔍 Step 1: Checking validator class attributes...
✅ All validators have required class attributes
```

### 修复 task_id UUID 格式错误

**步骤 1**: 生成标准 UUID

使用 Ruby 内置的 `SecureRandom.uuid` 生成：

```bash
# 生成单个标准 UUID
rails runner "puts SecureRandom.uuid"
# 输出: c0342467-8568-4bce-964c-4133c8367e7d

# 批量生成 10 个 UUID
rails runner "10.times { puts SecureRandom.uuid }"
```

**步骤 2**: 修复受影响的 validators

以 v125 为例：

```diff
# app/validators/v101_v150/v125_book_early_morning_flight_and_budget_hotel_validator.rb
module V101V150
  class V125BookEarlyMorningFlightAndBudgetHotelValidator < BaseValidator
    self.validator_id = 'v125_book_early_morning_flight_and_budget_hotel_validator'
-   self.task_id = 'd6e7f8g9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'  # 包含非法字符 'g'
+   self.task_id = 'd6e7f8a9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'  # 修复：g → a
```

**步骤 3**: 批量查找需要修复的 validators

```bash
# 运行 rake 命令会自动检测所有问题
rake validator:simulate

# 或使用分析脚本查看详细列表
rails runner tmp/analyze_validator_issues.rb
```

**步骤 4**: 验证修复

```bash
rake validator:simulate
```

成功输出：
```
🔍 Step 1: Checking validator class attributes...
✅ All validators have required class attributes
```

---

## 命名规范

### validator_id 格式要求

```
{version_prefix}_{task_description}_validator
```

- **version_prefix**: `v001` ~ `v999` (3位数字，带 `v` 前缀)
- **task_description**: 用下划线分隔的任务描述 (例如: `book_photography_theme_tour`)
- **suffix**: 必须以 `_validator` 结尾

#### 示例

| 文件名 | validator_id | ✅/❌ |
|--------|-------------|-------|
| `v299_book_photography_theme_tour_validator.rb` | `'v299_book_photography_theme_tour_validator'` | ✅ |
| `v308_book_diving_lesson_photography_validator.rb` | `'v308_book_diving_lesson_photography_validator'` | ✅ |
| `v299_book_photography_theme_tour_validator.rb` | `299` | ❌ (数字) |
| `v299_book_photography_theme_tour_validator.rb` | `'v300_wrong_name'` | ❌ (不一致) |

### task_id UUID 格式要求

```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

- **格式**: 8-4-4-4-12 (用连字符分隔)
- **字符**: 仅允许十六进制字符 `0-9`, `a-f` (不区分大小写)
- **总长度**: 36 字符（包含 4 个连字符）

#### 示例

| task_id | ✅/❌ | 说明 |
|---------|-------|------|
| `c0342467-8568-4bce-964c-4133c8367e7d` | ✅ | 标准 UUID |
| `f308a001-0001-4001-8001-000000000308` | ✅ | 自定义但符合格式 |
| `d6e7f8g9-0a1b-2c3d-4e5f-6a7b8c9d0e1f` | ❌ | 包含非法字符 'g' |
| `e7f8g9h0-1a2b-3c4d-5e6f-7a8b9c0d1e2f` | ❌ | 包含非法字符 'g', 'h' |
| `12345678-1234-1234-1234-1234567890` | ❌ | 格式错误（最后一段只有 10 位）|

#### 生成标准 UUID

```ruby
# 使用 SecureRandom.uuid
require 'securerandom'
SecureRandom.uuid
# => "c0342467-8568-4bce-964c-4133c8367e7d"
```

---

## 检查命令

### 手动检查单个 validator

**检查 validator_id**:
```bash
rails runner "puts V251V300::V299BookPhotographyThemeTourValidator.validator_id"
```

**检查 task_id**:
```bash
rails runner "puts V101V150::V125BookEarlyMorningFlightAndBudgetHotelValidator.task_id"
```

**验证 UUID 格式**:
```bash
rails runner "task_id = 'd6e7f8g9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'; puts task_id.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)"
# 输出: false (因为包含非法字符 'g')
```

### 批量检查所有 validators

**运行完整验证**:
```bash
rake validator:simulate  # 会在 Step 1 自动检查所有 validators
```

**仅运行 Step 1 检查**:
```bash
# Step 1 会检查:
# 1. 必需属性完整性 (validator_id, task_id, title, description, timeout_seconds)
# 2. validator_id 类型和格式
# 3. task_id UUID 格式
```

---

## 相关文件

- **Validator**: `app/validators/v251_v300/v299_book_photography_theme_tour_validator.rb`
- **Rake 任务**: `lib/tasks/validator.rake` (Step 1)
- **测试脚本**: `tmp/test_validator_id_format.rb`

---

## 总结

✅ **优化完成**：
1. 修复了 v299 的 `validator_id` 格式错误（`299` → `'v299_book_photography_theme_tour_validator'`）
2. 在 `rake validator:simulate` Step 1 中添加了 `validator_id` 类型和格式检查
3. 在 `rake validator:simulate` Step 1 中添加了 `task_id` UUID 格式检查
4. 发现 23 个 validators 有 `task_id` 格式问题（包含非十六进制字符）

✅ **检查内容**：

**validator_id 检查**:
- 类型检查：必须是 `String`
- 格式检查：必须与文件名一致

**task_id 检查**:
- 格式检查：必须符合标准 UUID 格式（8-4-4-4-12）
- 字符检查：只允许十六进制字符（0-9, a-f）
- 非法字符检测：明确指出包含哪些非法字符

✅ **错误提示**：
- 清晰的错误信息
- 期望值 vs 实际值对比
- 详细的错误原因（如：包含非十六进制字符 g, h）
- 修复建议（如：可使用 SecureRandom.uuid 生成）

✅ **发现的问题**：
- **23 个 validators** 的 `task_id` 包含非十六进制字符
- 需要使用标准 UUID 或修复现有 UUID 中的非法字符

**现在 validator_id 和 task_id 的格式问题都能在 `rake validator:simulate` 的 Step 1 中被检测出来！** 🎉
