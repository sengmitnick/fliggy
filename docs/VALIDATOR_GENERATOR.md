# Validator Generator Documentation

## Overview

The validator generator automates the creation of new validator files with:
- **Auto-generated UUID** for `task_id` field
- **Auto-incremented validator number** (e.g., v098, v099, v100)
- **Complete boilerplate code** with best practices
- **Comprehensive inline documentation** and examples

## Quick Start

```bash
rails generate validator VALIDATOR_NAME "中文标题" "中文描述"
```

### Example

```bash
rails generate validator book_premium_hotel "预订高档酒店" "用户需要预订五星级酒店，价格不限"
```

This creates `app/validators/v098_book_premium_hotel_validator.rb` with:
- `validator_id`: `v098_book_premium_hotel_validator`
- `task_id`: `8cf22f3f-c196-4f35-b70c-03327c21b808` (auto-generated UUID)
- `title`: `预订高档酒店`
- `description`: `用户需要预订五星级酒店，价格不限`

## Generated File Structure

```ruby
# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例098: 预订高档酒店
#
# 任务描述:
#   用户需要预订五星级酒店，价格不限
#
# 评分标准:
#   - TODO: 定义评分标准
class V098BookPremiumHotelValidator < BaseValidator
  self.validator_id = 'v098_book_premium_hotel_validator'
  self.task_id = '8cf22f3f-c196-4f35-b70c-03327c21b808'  # ✅ Auto-generated UUID
  self.title = '预订高档酒店'
  self.description = '用户需要预订五星级酒店，价格不限'
  self.timeout_seconds = 300
  
  def prepare
    # TODO: Implement task parameters
  end
  
  def verify
    # TODO: Add assertions
  end
  
  def simulate
    # TODO: Implement AI agent logic
  end
  
  private
  
  def execution_state_data
    # TODO: Save state
  end
  
  def restore_from_state(data)
    # TODO: Restore state
  end
end
```

## Why UUID is Important

### Problem Without UUID
Before the generator, validators only had `validator_id` (string like `v001_book_hotel_validator`):
- Hard to use as unique identifier in external systems
- Requires string parsing to extract validator number
- Not globally unique across different environments

### Solution with UUID
Now every validator has both:
1. **`validator_id`** (human-readable): `v098_book_premium_hotel_validator`
2. **`task_id`** (UUID): `8cf22f3f-c196-4f35-b70c-03327c21b808`

Benefits:
- ✅ Globally unique identifier
- ✅ Easy to reference in APIs and databases
- ✅ Compatible with external systems expecting UUIDs
- ✅ Backward compatible (both fields exist)

## Implementation Steps

After generation, you need to implement three main methods:

### 1. `prepare` Method

Set task parameters and return task information:

```ruby
def prepare
  @city = '深圳'
  @budget = 500
  @check_in_date = Date.current + 2.days
  
  {
    task: "请预订#{@city}的酒店，预算≤#{@budget}元",
    city: @city,
    budget: @budget,
    check_in_date: @check_in_date.to_s,
    hint: "系统中有多家酒店可选，请选择性价比最高的"
  }
end
```

**Key Points:**
- Use `@instance_variables` to store parameters (needed in `verify`)
- Return hash must include `task` field
- Query baseline data with `data_version: 0`

### 2. `verify` Method

Add assertions to validate task completion:

```ruby
def verify
  # First assertion: Core operation completed (weight: 20-30)
  add_assertion "订单已创建", weight: 20 do
    @order = HotelBooking
      .where(data_version: @data_version)  # ⚠️ CRITICAL: Filter by data_version
      .order(created_at: :desc)
      .first
    expect(@order).not_to be_nil, "未找到任何订单"
  end
  
  # Guard clause
  return unless @order
  
  # Subsequent assertions: Validate attributes (weight: 10-20 each)
  add_assertion "城市正确", weight: 15 do
    expect(@order.hotel.city).to eq(@city),
      "城市错误。期望: #{@city}, 实际: #{@order.hotel.city}"
  end
  
  add_assertion "价格符合预算", weight: 30 do
    expect(@order.total_price <= @budget).to be_truthy,
      "价格超出预算。预算: ≤#{@budget}元, 实际: #{@order.total_price}元"
  end
  
  # ... more assertions
end
```

**Best Practices:**
- ✅ **Total weights must sum to 100**
- ✅ **First assertion**: Query records and store in `@instance_variable`
- ✅ **Always filter by `data_version`** in first assertion query
- ✅ **Use guard clause** (`return unless @record`) after first assertion
- ✅ **Provide clear error messages** in `expect` statements
- ✅ **Separate assertions** for different attributes (better scoring granularity)

**Query Pattern:**
```ruby
# ✅ GOOD: Filter by data_version + entity filters only
all_orders = HotelBooking
  .joins(:hotel)
  .where(hotels: { city: @city })           # Entity filter
  .where(data_version: @data_version)        # Session isolation
  .order(created_at: :desc)
  .to_a

# ❌ BAD: Don't filter by attributes to validate
all_orders = HotelBooking
  .where(check_in_date: @check_in_date)     # Wrong! Should validate separately
  .where(data_version: @data_version)
```

### 3. `simulate` Method

Implement AI agent automation logic:

```ruby
def simulate
  # 1. Find test user (from data pack)
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  
  # 2. Find target data (filter by data_version: 0)
  hotel = Hotel
    .where(city: @city, data_version: 0)
    .where('price <= ?', @budget)
    .order(rating: :desc)
    .first
  
  raise "未找到符合条件的酒店" unless hotel
  
  # 3. Create order (use data_version: @data_version)
  HotelBooking.create!(
    user_id: user.id,
    hotel_id: hotel.id,
    check_in_date: @check_in_date,
    total_price: hotel.price,
    data_version: @data_version  # ⚠️ CRITICAL: Use current execution's data_version
  )
end
```

**Key Rules:**
- ✅ Query baseline data with `data_version: 0`
- ✅ Create records with `data_version: @data_version`
- ✅ Raise clear errors if data not found

## data_version Field

**Critical Concept:** All validators use `data_version` for data isolation.

### Two Types of data_version:

1. **`data_version: 0`** (Baseline Data)
   - Pre-loaded data from `app/validators/support/data_packs/v1/`
   - Shared across all validator executions
   - Used for: Hotels, Flights, Users, etc.

2. **`data_version: @data_version`** (Execution Data)
   - Unique per validator execution (e.g., `df45d7a9ac7cfadb`)
   - Created during `simulate` method
   - Used for: Orders, Bookings, etc.

### Query Pattern:

```ruby
# In prepare method: Query baseline data
Hotel.where(data_version: 0).where(city: '深圳')

# In verify method: Query execution data
HotelBooking.where(data_version: @data_version).order(created_at: :desc)

# In simulate method:
# - Query baseline (data_version: 0)
# - Create execution data (data_version: @data_version)
hotel = Hotel.find_by!(name: '深圳酒店', data_version: 0)
HotelBooking.create!(hotel_id: hotel.id, data_version: @data_version)
```

## Testing

After implementation, test your validator:

```bash
# Test all validators
rake validator:simulate

# Test single validator
rails runner "v = V098BookPremiumHotelValidator.new; v.execute_prepare; v.execute_simulate; puts v.execute_verify"
```

Expected output:
```
v098_book_premium_hotel_validator
✓ PASSED (100/100)
```

## Weight Distribution Guidelines

Total must sum to 100. Recommended distribution:

- **Existence + Count**: 20-25% (first assertion)
- **Core Entity Correct**: 10-15% (e.g., hotel name, attraction name)
- **Basic Attributes**: 10-15% each (e.g., date, quantity, room type)
- **Business Logic**: 20-30% (e.g., price optimization, complex validation)

Example:
```ruby
add_assertion "创建了订单", weight: 20          # Existence
add_assertion "酒店正确", weight: 15             # Entity
add_assertion "入住日期正确", weight: 10         # Attribute
add_assertion "价格符合预算", weight: 30         # Business logic
add_assertion "选择了最优酒店", weight: 25       # Optimization
# Total: 100
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Filtering by validation attribute in query
```ruby
# BAD: visit_date in query
all_orders = TicketOrder.where(visit_date: @visit_date, data_version: @data_version)
expect(all_orders).not_to be_empty  # Error: "未找到订单" (unhelpful)
```

**Fix:**
```ruby
# GOOD: visit_date in separate assertion
all_orders = TicketOrder.where(data_version: @data_version)
add_assertion "游玩日期正确", weight: 10 do
  all_orders.each { |o| expect(o.visit_date).to eq(@visit_date) }  # Error: "游玩日期错误" (helpful)
end
```

### ❌ Mistake 2: Forgetting data_version filter
```ruby
# BAD: No data_version filter
all_orders = TicketOrder.where(user_id: @user_id)
```

**Fix:**
```ruby
# GOOD: Include data_version
all_orders = TicketOrder.where(user_id: @user_id, data_version: @data_version)
```

### ❌ Mistake 3: Not using guard clause
```ruby
# BAD: No guard clause
add_assertion "创建了订单" do
  @orders = TicketOrder.where(data_version: @data_version)
end
add_assertion "日期正确" do
  @orders.each { |o| expect(o.visit_date).to eq(@date) }  # Crashes if @orders is empty
end
```

**Fix:**
```ruby
# GOOD: Guard clause
add_assertion "创建了订单" do
  @orders = TicketOrder.where(data_version: @data_version)
end
return if @orders.nil? || @orders.empty?  # Guard
add_assertion "日期正确" do
  @orders.each { |o| expect(o.visit_date).to eq(@date) }
end
```

## Summary

✅ **All 97 existing validators have UUIDs** (v001-v097)

✅ **Generator automatically creates:**
- Next validator number
- UUID for task_id
- Complete boilerplate code
- Best practice examples

✅ **When creating new validators:**
1. Use `rails generate validator`
2. Implement `prepare`, `verify`, `simulate`
3. Follow `data_version` pattern
4. Test with `rake validator:simulate`

✅ **Key Rules:**
- Total assertion weights = 100
- Query with `data_version` filters
- First assertion queries and stores data
- Use guard clauses
- Provide clear error messages

---

For more details, see:
- `app/validators/base_validator.rb` - Base class implementation
- `docs/project.md` - Validator verify method best practices
- `lib/generators/validator/USAGE` - Generator usage guide
