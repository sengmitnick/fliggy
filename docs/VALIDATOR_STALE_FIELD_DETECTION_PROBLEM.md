# Validator 过时字段检测问题 - 深度分析

## 📋 文档信息

- **创建时间**: 2026-02-04
- **触发案例**: v010_search_cheapest_flight_validator
- **问题严重程度**: 🔴 **CRITICAL** - 影响验证器可靠性和代码库健康度

---

## 🎯 问题概述

### 核心问题

**验证器（Validator）使用了数据库中存在但前端不再使用的过时字段（Stale Fields），导致测试场景与实际业务逻辑严重脱节，但 `rake validator:simulate` 无法检测到此问题。**

### 问题的严重性

1. **静默失败（Silent Failure）**: 验证器测试可以通过，但测试的是错误的业务逻辑
2. **错误的信心（False Confidence）**: 100% 通过率掩盖了实际问题
3. **技术债累积（Technical Debt）**: 过时字段继续被引用，阻碍代码重构
4. **误导性文档（Misleading Documentation）**: 验证器成为错误的系统行为参考

---

## 📊 案例分析: v010_search_cheapest_flight_validator

### 时间线

| 时间点 | 事件 | 影响 |
|--------|------|------|
| **Phase 1** | Flight.discount_price 字段被创建 | 用于存储航班折扣金额 |
| **Phase 2** | FlightOffer 模型引入，包含 cashback_amount 字段 | 新的业务逻辑：返现后成本 = price - cashback_amount |
| **Phase 3** | 前端迁移到 FlightOffer，不再显示 discount_price | Flight.discount_price 成为 **遗留字段（Legacy Field）** |
| **Phase 4** | v010 验证器创建时使用了 discount_price | ❌ 使用过时字段，测试错误的业务逻辑 |
| **Phase 5** | rake validator:simulate 测试通过 | ⚠️ 静默失败 - 没有任何警告 |
| **Phase 6** | 用户发现实际订单金额不匹配 | 🔴 问题暴露：验证器期望 ¥500，实际 ¥450 |

### 证据链

#### 1. 数据库层面 - discount_price 字段存在

```ruby
# db/schema.rb (Line 820)
create_table "flights" do |t|
  t.decimal "discount_price", default: "0.0"
  # ...
end
```

**状态**: ✅ 字段存在于数据库

#### 2. 模型层面 - discount_price 可访问

```ruby
# app/models/flight.rb (Lines 199-202)
def final_price
  price - discount_price  # ❌ 使用过时字段
end

def discount_percent
  return 100 if discount_price.nil? || discount_price.zero?
  # ...
end
```

**状态**: ✅ 模型方法可正常调用（没有 NoMethodError）

#### 3. 数据包层面 - discount_price 有数据

```ruby
# app/validators/support/data_packs/v1/flights.rb
Flight.insert_all([
  {
    flight_number: '9C8765',
    price: 450.0,
    discount_price: 0.0,  # ✅ 数据存在
    # ...
  },
  {
    flight_number: 'HO1234',
    price: 520.0,
    discount_price: 20.0,  # ✅ 有折扣数据
    # ...
  }
])
```

**状态**: ✅ 数据包提供完整数据，验证器查询不报错

#### 4. 前端层面 - discount_price **未被使用**

```erb
<!-- app/views/flights/search.html.erb (Lines 73, 110-114) -->
<!-- ✅ 实际使用 FlightOffer 数据 -->
<div class="text-lg font-bold text-red-500">
  ¥<%= flight.min_offer_price.to_i %>
</div>

<% cheapest_offer = flight.flight_offers.order(:price).first %>
<% if cheapest_offer && cheapest_offer.cashback_amount > 0 %>
  <div class="mt-2">
    <span class="text-xs px-2 py-0.5 bg-red-50 text-red-600 rounded">
      返现¥<%= cheapest_offer.cashback_amount.to_i %>
    </span>
  </div>
<% end %>

<!-- ❌ discount_price 完全不存在于此视图 -->
```

```erb
<!-- app/views/bookings/new.html.erb (Lines 54, 105, 154) -->
<!-- ⚠️ MISLEADING: 显示为"机建燃油"，实际是错误的字段映射 -->
<div class="text-gray-600">
  成人 ¥<%= (@selected_offer&.price || @flight.final_price).to_i %>
  机建燃油 ¥<%= @flight.discount_price.to_i %>  <!-- ❌ 错误使用 -->
</div>
```

**状态**: ❌ 前端主要流程不使用 discount_price

#### 5. 验证器层面 - 使用过时字段（修复前）

```ruby
# v010_search_cheapest_flight_validator.rb (修复前)
def prepare
  flights = Flight.where(...)
  
  @flight_prices = flights.map do |f|
    {
      original_price: f.price,
      discount: f.discount_price,  # ❌ 使用过时字段
      final_price: f.price - f.discount_price  # ❌ 错误的计算逻辑
    }
  end
end

def verify
  cheapest = all_flights.min_by { |f| f.price - f.discount_price }  # ❌ 错误逻辑
  expect(@booking.total_price).to eq(cheapest.price - cheapest.discount_price)  # ❌ 错误期望
end
```

**问题**: 验证器测试的是 `Flight.discount_price` 逻辑，而实际业务使用 `FlightOffer.cashback_amount`

---

## 🔍 问题根因分析

### 为什么 rake validator:simulate 无法检测？

#### 1. **完整的数据链路（Complete Data Path）**

```
数据库字段存在
    ↓
模型方法可调用
    ↓
数据包提供数据
    ↓
验证器查询成功
    ↓
断言逻辑正确（基于错误假设）
    ↓
✅ 测试通过（100/100）
```

**关键问题**: 每一层都"正常工作"，但整体逻辑与实际业务脱节

#### 2. **缺少前后端契约验证（Missing Frontend-Backend Contract Validation）**

```ruby
# 验证器只验证后端逻辑一致性
expect(@booking.total_price).to eq(expected_price)  # ✅ 后端数据一致

# ❌ 但没有验证"expected_price 的计算方式是否与前端一致"
# 前端: offer.price - offer.cashback_amount
# 验证器: flight.price - flight.discount_price  
# → 两者计算不同，但都能通过测试
```

#### 3. **过时字段的生命周期问题（Stale Field Lifecycle）**

```
阶段1: 字段被创建和使用
    ├─ 数据库: CREATE TABLE flights (discount_price decimal)
    ├─ 模型: def final_price = price - discount_price
    ├─ 视图: <%= flight.discount_price %>
    └─ 验证器: 使用 discount_price ✅ 正确

阶段2: 业务逻辑迁移
    ├─ 新模型: FlightOffer (cashback_amount)
    ├─ 视图更新: 改用 flight_offers.cashback_amount
    └─ 旧字段: discount_price 仍存在 ⚠️ 未删除

阶段3: 验证器继续使用旧字段
    ├─ 数据库: discount_price 仍有数据
    ├─ 模型: 方法仍可调用
    ├─ 验证器: 查询成功，测试通过 ✅
    └─ 实际: 测试的是错误的业务逻辑 ❌
```

---

## 🚨 影响范围评估

### 已知影响

| 模型 | 可疑字段 | 使用位置 | 风险等级 |
|------|----------|----------|----------|
| **Flight** | `discount_price` | 验证器（已修复）、bookings/new.html.erb (line 54, 105, 154) | 🔴 HIGH |
| **Flight** | `final_price` (方法) | 计算依赖 discount_price | 🟡 MEDIUM |
| **Flight** | `discount_percent` (方法) | 计算依赖 discount_price | 🟡 MEDIUM |

### 潜在影响（需进一步调查）

```ruby
# 以下场景也可能存在过时字段问题：

# 1. Train 模型 - 可能有类似的价格字段演化
# 2. Hotel/HotelRoom - 价格结构可能已变化
# 3. TourGroupProduct - duration_text vs duration (integer)
# 4. 任何有关联模型的字段（一对多、多对多场景）
```

---

## 💡 深层次问题

### 1. **Schema Evolution 缺乏治理（Lack of Schema Governance）**

**问题**: 数据库字段可以"僵尸化"（存在但不使用）而不被发现

```ruby
# 正常流程应该是：
1. 发现字段不再使用 → 2. 标记为 deprecated → 3. 迁移数据 → 4. 删除字段

# 实际情况：
1. 引入新字段/模型 → 2. 前端改用新字段 → 3. 旧字段继续存在 → 4. 无人知晓
```

### 2. **验证器与前端视图解耦（Validator-View Decoupling）**

**问题**: 验证器测试后端逻辑，但不验证"这是否是前端实际使用的逻辑"

```ruby
# 验证器设计假设：
"如果后端逻辑自洽，且数据正确，则系统正常工作"

# 现实：
"后端逻辑可以自洽，但与前端使用的逻辑完全不同"
```

### 3. **字段使用度缺乏可见性（Field Usage Visibility）**

**问题**: 无法快速回答"这个字段是否还在被使用？"

当前需要：
- 全局搜索代码库
- 检查视图、控制器、模型
- 分析前端 JavaScript
- 查看 API 响应

理想状态：
- 字段使用度仪表板
- 废弃字段自动标记
- 前后端契约验证

---

## 🎯 问题的本质

### 核心矛盾

```
验证器的职责:
  验证"系统按照规格说明书工作"

实际情况:
  规格说明书本身可能过时（使用了遗留字段）
  但验证器无法检测规格说明书是否过时
```

### 类比

```
这就像：
  一个质检员（Validator）严格检查产品是否符合图纸
  图纸上写着"使用铜制螺丝"
  但实际生产线早已改用"不锈钢螺丝"
  质检员验证通过（产品确实用了铜制螺丝）
  但产品无法与生产线其他部件配合使用
```

---

## 📈 数据支撑

### v010 修复前后对比

| 指标 | 修复前 | 修复后 | 变化 |
|------|--------|--------|------|
| **测试通过率** | 100/100 ✅ | 100/100 ✅ | 无变化 |
| **使用字段** | Flight.discount_price | FlightOffer.cashback_amount | ✅ 对齐前端 |
| **业务逻辑** | price - discount_price | offer.price - offer.cashback_amount | ✅ 对齐实际 |
| **查询模型** | Flight 直接查询 | FlightOffer joins Flight | ✅ 对齐架构 |
| **实际场景** | ❌ 错误场景 | ✅ 真实场景 | **关键差异** |

### 发现时机

```
创建时间: 未知（可能数月前）
          ↓
使用期间: 一直测试通过 ✅
          ↓
发现时间: 2026-02-04（用户报告不匹配）
          ↓
修复时间: 2026-02-04（重构验证器）
```

**静默期**: 可能数月未被发现，期间所有测试都"通过"

---

## 🔧 目前的临时解决方案（已实施）

### v010 验证器重构

```ruby
# ✅ 修复后的逻辑
def prepare
  flights = Flight.where(...).includes(:flight_offers)
  
  @offer_prices = []
  flights.each do |flight|
    flight.flight_offers.each do |offer|
      @offer_prices << {
        price: offer.price,
        cashback_amount: offer.cashback_amount,
        final_cost: offer.price - offer.cashback_amount  # ✅ 正确逻辑
      }
    end
  end
end

def verify
  # ✅ 使用 FlightOffer 查询
  all_offers = FlightOffer.joins(:flight).where(...)
  cheapest = all_offers.min_by { |o| o.price - o.cashback_amount }
  
  # ✅ 验证实际使用的字段
  expect(@booking.total_price).to eq(cheapest.price)
end
```

**局限性**: 
- ✅ 修复了这一个验证器
- ❌ 但无法防止未来创建新的使用过时字段的验证器
- ❌ 无法检测其他现有验证器是否有类似问题

---

## 🤔 根本性解决方案探讨

### 方案对比

| 方案 | 优点 | 缺点 | 实施难度 | 推荐度 |
|------|------|------|----------|--------|
| **A. 静态代码分析** | 可检测字段使用 | 误报率高，无法理解语义 | 🟡 MEDIUM | ⭐⭐ |
| **B. 前后端契约测试** | 确保前后端一致 | 需要维护契约定义 | 🔴 HIGH | ⭐⭐⭐⭐ |
| **C. 字段使用度追踪** | 可视化字段使用 | 运行时开销，需额外工具 | 🔴 HIGH | ⭐⭐⭐ |
| **D. Schema 版本管理** | 强制字段生命周期 | 增加开发负担 | 🔴 HIGH | ⭐⭐⭐ |
| **E. 验证器 Lint 工具** | 自动检测常见问题 | 无法覆盖所有场景 | 🟢 LOW | ⭐⭐⭐⭐⭐ |
| **F. 定期人工审查** | 成本低，灵活 | 不可靠，容易遗漏 | 🟢 LOW | ⭐⭐ |

### 推荐组合方案

```
短期（1-2周）:
  1. ✅ 修复已知问题（v010 已完成）
  2. 🔄 人工审查所有现有验证器
  3. 📝 更新 .clackyrules 添加最佳实践

中期（1-2月）:
  1. 🛠️ 开发 Validator Lint 工具（方案E）
  2. 📋 建立字段使用度追踪（方案C简化版）
  3. 🧪 引入前后端契约测试（方案B试点）

长期（3-6月）:
  1. 🏗️ Schema 版本管理系统（方案D）
  2. 🤖 自动化字段废弃流程
  3. 📊 字段健康度仪表板
```

---

## 📋 方案详细设计

### 方案 E: Validator Lint 工具（推荐优先实施）

#### 设计思路

```ruby
# lib/tasks/validator_lint.rake

namespace :validator do
  desc "Lint validators for common issues (stale fields, missing associations)"
  task lint: :environment do
    linter = ValidatorLinter.new
    
    issues = [
      linter.check_stale_fields,      # 检测过时字段使用
      linter.check_missing_includes,  # 检测 N+1 查询
      linter.check_view_alignment,    # 检测与视图不一致
      linter.check_data_version       # 检测缺失 data_version
    ].flatten
    
    if issues.any?
      puts "❌ Found #{issues.size} issues:"
      issues.each { |issue| puts "  - #{issue}" }
      exit 1
    else
      puts "✅ All validators passed lint checks"
    end
  end
end
```

#### 核心检测逻辑

```ruby
class ValidatorLinter
  # 检测1: 过时字段使用
  def check_stale_fields
    issues = []
    
    STALE_FIELDS = {
      'Flight' => ['discount_price', 'final_price (method)'],
      'Train' => [],  # TBD: 需要调查
      'Hotel' => []   # TBD: 需要调查
    }
    
    validator_files.each do |file|
      content = File.read(file)
      validator_name = File.basename(file, '.rb')
      
      STALE_FIELDS.each do |model, fields|
        fields.each do |field|
          if content.match?(/#{model}.*\.#{field}/)
            issues << {
              validator: validator_name,
              model: model,
              field: field,
              severity: 'HIGH',
              message: "使用了过时字段 #{model}.#{field}",
              suggestion: check_alternative_field(model, field)
            }
          end
        end
      end
    end
    
    issues
  end
  
  # 检测2: 视图对齐检查
  def check_view_alignment
    issues = []
    
    # 例如：验证器使用 Flight.discount_price，
    # 但 flights/search.html.erb 不包含此字段
    validator_fields = extract_fields_from_validators
    view_fields = extract_fields_from_views
    
    mismatches = validator_fields - view_fields
    mismatches.each do |field|
      issues << {
        field: field,
        severity: 'MEDIUM',
        message: "验证器使用了 #{field}，但视图中未找到"
      }
    end
    
    issues
  end
  
  # 检测3: data_version 过滤检查
  def check_data_version
    issues = []
    
    validator_files.each do |file|
      content = File.read(file)
      validator_name = File.basename(file, '.rb')
      
      # 检测 .where(...) 但没有 data_version
      if content.match?(/\.where\([^)]+\)/) && !content.match?(/data_version.*@data_version/)
        issues << {
          validator: validator_name,
          severity: 'HIGH',
          message: "查询缺少 data_version 过滤"
        }
      end
    end
    
    issues
  end
end
```

#### 使用方式

```bash
# 开发时手动运行
$ rake validator:lint

# CI/CD 集成
$ rake validator:lint && rake validator:simulate

# 单文件检查
$ rake validator:lint[v010_search_cheapest_flight_validator]
```

#### 输出示例

```
🔍 Linting validators...

❌ Found 3 issues:

[HIGH] v010_search_cheapest_flight_validator
  → 使用了过时字段 Flight.discount_price
  → 建议: 改用 FlightOffer.cashback_amount
  → 位置: Line 58, 132

[MEDIUM] v023_book_first_class_train_validator
  → 验证器使用了 Train.discount_price，但视图中未找到
  → 建议: 检查前端是否使用此字段

[HIGH] v045_book_hotel_validator
  → 查询缺少 data_version 过滤
  → 位置: Line 67: Hotel.where(city: @city)
  → 建议: 添加 .where(data_version: 0)

---
❌ Lint failed. Please fix the issues above.
```

---

### 方案 B: 前后端契约测试（中期实施）

#### 设计思路

```yaml
# spec/contracts/flight_booking_contract.yml
contract: flight_booking
version: 1.0

frontend_expectations:
  # 前端期望的数据结构
  flight_search_response:
    fields:
      - flight_number
      - departure_time
      - arrival_time
      - min_offer_price  # ✅ 前端使用此字段
    
  flight_offers:
    fields:
      - provider_name
      - price
      - cashback_amount  # ✅ 前端使用此字段
      - final_price (computed)
    
  deprecated_fields:
    - discount_price  # ❌ 前端不再使用

backend_implementation:
  models:
    - Flight
    - FlightOffer
  
  validators:
    - v010_search_cheapest_flight_validator:
        must_use_fields:
          - FlightOffer.price
          - FlightOffer.cashback_amount
        must_not_use_fields:
          - Flight.discount_price  # ❌ 验证器不应使用
```

#### 契约验证测试

```ruby
# spec/contracts/flight_booking_contract_spec.rb
RSpec.describe "Flight Booking Contract", type: :contract do
  let(:contract) { ContractLoader.load('flight_booking_contract.yml') }
  
  describe "Frontend Expectations" do
    it "视图使用的所有字段都在契约中定义" do
      view_fields = extract_fields_from_view('flights/search.html.erb')
      expect(view_fields).to match_array(contract.frontend_fields)
    end
    
    it "视图不使用废弃字段" do
      view_content = File.read('app/views/flights/search.html.erb')
      contract.deprecated_fields.each do |field|
        expect(view_content).not_to include(field)
      end
    end
  end
  
  describe "Validator Alignment" do
    it "v010 验证器使用契约定义的字段" do
      validator_content = File.read('app/validators/.../v010_..._validator.rb')
      
      contract.must_use_fields.each do |field|
        expect(validator_content).to include(field),
          "验证器应该使用 #{field}（前端契约要求）"
      end
      
      contract.must_not_use_fields.each do |field|
        expect(validator_content).not_to include(field),
          "验证器不应使用 #{field}（已废弃）"
      end
    end
  end
end
```

#### 优点

- ✅ 明确前后端期望
- ✅ 自动检测不一致
- ✅ 契约文件作为文档

#### 缺点

- ❌ 需要维护契约文件
- ❌ 增加开发流程复杂度
- ❌ 契约本身也可能过时

---

### 方案 C: 字段使用度追踪（中期实施）

#### 设计思路

```ruby
# lib/field_usage_tracker.rb
class FieldUsageTracker
  # 扫描代码库，记录字段使用位置
  def scan_codebase
    usage_map = {}
    
    # 扫描视图
    Dir['app/views/**/*.html.erb'].each do |file|
      content = File.read(file)
      extract_field_accesses(content).each do |field|
        usage_map[field] ||= { views: [], controllers: [], validators: [] }
        usage_map[field][:views] << file
      end
    end
    
    # 扫描控制器
    Dir['app/controllers/**/*.rb'].each do |file|
      # ...类似逻辑
    end
    
    # 扫描验证器
    Dir['app/validators/**/*.rb'].each do |file|
      # ...类似逻辑
    end
    
    usage_map
  end
  
  # 生成报告
  def generate_report
    usage_map = scan_codebase
    
    # 找出零使用字段
    zero_usage_fields = find_zero_usage_fields(usage_map)
    
    # 找出仅被验证器使用的字段（可疑）
    validator_only_fields = usage_map.select do |field, locations|
      locations[:views].empty? && 
      locations[:controllers].empty? && 
      locations[:validators].any?
    end
    
    {
      total_fields: usage_map.size,
      zero_usage: zero_usage_fields,
      validator_only: validator_only_fields,  # ⚠️ 可疑字段
      high_usage: usage_map.select { |_, locs| total_locations(locs) > 10 }
    }
  end
end
```

#### 使用方式

```bash
$ rake field_usage:scan

📊 Field Usage Report
====================

⚠️ Validator-Only Fields (可疑):
  - Flight.discount_price
    使用位置:
      - app/validators/v001_v050/v010_...
      - app/models/flight.rb (final_price method)
    前端使用: 0 次
    建议: 检查是否为过时字段

✅ High Usage Fields:
  - Flight.flight_number (47 次)
  - FlightOffer.price (35 次)
  - FlightOffer.cashback_amount (28 次)

❌ Zero Usage Fields:
  - Flight.some_old_field (0 次)
  建议: 考虑删除
```

---

### 方案 D: Schema 版本管理（长期实施）

#### 设计思路

```ruby
# db/schema_versions/v2_flight_pricing_refactor.rb
class V2FlightPricingRefactor < SchemaVersion
  version 2
  description "从 Flight.discount_price 迁移到 FlightOffer.cashback_amount"
  
  deprecate do
    field 'flights.discount_price', 
      reason: '业务逻辑已迁移到 FlightOffer',
      deprecated_at: '2025-12-01',
      remove_at: '2026-06-01',  # 6个月后删除
      migration_guide: 'docs/migrations/flight_pricing.md'
  end
  
  introduce do
    model 'FlightOffer',
      reason: '支持多套餐定价',
      fields: ['price', 'cashback_amount', 'provider_name']
  end
  
  validation do
    # 自动验证：废弃字段不应被新代码使用
    ensure_no_new_usage_of('flights.discount_price') do
      allow_existing_usage_in([
        'app/validators/v010_...',  # 已知遗留使用
        'app/models/flight.rb'      # 向后兼容方法
      ])
    end
  end
end
```

#### Git Hook 集成

```bash
# .git/hooks/pre-commit
#!/bin/bash

# 检查是否使用了废弃字段
if git diff --cached | grep -q 'discount_price'; then
  echo "⚠️  警告：您正在使用废弃字段 'discount_price'"
  echo "   此字段将在 2026-06-01 删除"
  echo "   请改用 FlightOffer.cashback_amount"
  echo ""
  echo "   参考文档: docs/migrations/flight_pricing.md"
  echo ""
  read -p "   是否继续提交? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi
```

---

## 📝 行动计划

### Phase 1: 立即行动（本周）

- [x] ✅ 修复 v010_search_cheapest_flight_validator
- [ ] 🔄 审查所有 Flight 相关验证器
- [ ] 📝 更新 .clackyrules 添加过时字段检测指南
- [ ] 🔍 标记 bookings/new.html.erb 中的错误 discount_price 使用

### Phase 2: 短期（2周内）

- [ ] 🛠️ 开发 Validator Lint 工具基础版本
  - [ ] 实现 check_stale_fields
  - [ ] 实现 check_data_version
  - [ ] 集成到 rake validator:simulate 前置检查
- [ ] 📋 创建字段使用度追踪脚本
- [ ] 🧪 全面审查现有 256 个验证器

### Phase 3: 中期（1-2月）

- [ ] 🏗️ 完善 Validator Lint 工具
  - [ ] 实现 check_view_alignment
  - [ ] 添加自动修复建议
  - [ ] CI/CD 集成
- [ ] 📄 试点前后端契约测试（Flight/FlightOffer 模块）
- [ ] 📊 建立字段健康度仪表板

### Phase 4: 长期（3-6月）

- [ ] 🏗️ Schema 版本管理系统
- [ ] 🤖 自动化字段废弃流程
- [ ] 📚 建立字段生命周期文档

---

## 🎓 经验教训

### 1. **数据库字段不是"删了就好"**

过时字段删除需要考虑：
- ✅ 数据迁移策略
- ✅ 向后兼容性
- ✅ 依赖方通知
- ✅ 回滚计划

### 2. **验证器不仅测试"正确性"，还要测试"相关性"**

```ruby
# 不够的：
expect(booking.total_price).to eq(expected_price)  # ✅ 数字正确

# 更好的：
expect(booking.total_price).to eq(expected_price) && 
  expect(expected_price).to be_calculated_using_frontend_logic  # ✅ 逻辑对齐
```

### 3. **静默失败比显式错误更危险**

```
显式错误: NoMethodError - 立即发现，快速修复
静默失败: 测试通过 - 数月未发现，影响范围扩大
```

### 4. **前后端解耦需要契约保障**

前后端分离带来灵活性，但也需要机制确保：
- 数据结构一致
- 业务逻辑对齐
- 废弃流程同步

---

## 📚 参考资源

### 内部文档

- [.clackyrules](../.clackyrules) - Line 737-751: Validator Testing
- [VALIDATOR_GENERATOR.md](./VALIDATOR_GENERATOR.md) - 验证器开发指南
- [lib/tasks/validator.rake](../lib/tasks/validator.rake) - Line 565-647: simulate_single 任务

### 相关 Issue

- v010_search_cheapest_flight_validator 重构 (2026-02-04)
  - 问题: 使用 Flight.discount_price 而非 FlightOffer.cashback_amount
  - 修复: 完全重构为 FlightOffer 场景
  - 测试: ✅ 100/100 通过

### 外部参考

- [Contract Testing Best Practices](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Database Schema Evolution](https://www.thoughtworks.com/insights/blog/evolutionary-database-design)
- [Deprecation Strategies](https://stripe.com/blog/api-versioning)

---

## 🤝 贡献指南

如果你发现新的过时字段问题：

1. **报告问题**
   ```
   - 字段名称: Flight.discount_price
   - 发现位置: v010_search_cheapest_flight_validator
   - 实际使用: FlightOffer.cashback_amount
   - 影响范围: 1个验证器，3个视图
   ```

2. **更新本文档**
   - 添加到"已知影响"表格
   - 记录修复过程
   - 分享经验教训

3. **改进工具**
   - 提交 Validator Lint 检测规则
   - 完善字段使用度追踪
   - 增强契约测试覆盖

---

## 📞 联系方式

如有疑问或建议，请通过以下方式联系：

- 项目 Issue: [创建新 Issue]
- 文档更新: Pull Request to `docs/VALIDATOR_STALE_FIELD_DETECTION_PROBLEM.md`

---

**最后更新**: 2026-02-04  
**文档版本**: 1.0  
**维护者**: @AI-Assistant
