# Bugfix: VisaProduct Slug Missing (Validation Error)

## 问题描述

在修复了系统中所有 FriendlyId slug 缺失问题后，发现 VisaProduct 还有 1/36 条记录缺失 slug（97% 覆盖率）。

### 初步症状

```bash
cd /home/runner/app && rails runner "puts 'VisaProduct: ' + VisaProduct.where(slug: [nil, '']).count.to_s + '/' + VisaProduct.count.to_s"
# 输出: VisaProduct: 1/36
```

## 根本原因分析

### 1. 缺失 slug 的记录

通过 rails runner 检查发现：

```ruby
vp = VisaProduct.where(slug: [nil, '']).first
# ID: 23
# 名称: 泰国落地签证
# 国家: 泰国
# data_version: 0
```

### 2. 尝试手动生成 slug

```ruby
vp.save
# 保存后 slug: c13bd3c2-b026-4b03-b22a-6dfeeac2f2e5  (UUID fallback)
# Errors: Processing days必须大于0
```

**关键发现**：
- `.save` 调用触发了验证错误：`Processing days必须大于0`
- 由于验证失败，FriendlyId 无法生成正常的 slug，退回到 UUID
- 验证错误导致 slug 始终为 nil 或 UUID

### 3. 数据源问题

检查 `app/validators/support/data_packs/v1/visa_services.rb` 第 508 行：

```ruby
# 泰国签证产品（扩充到4个）
[
  { type: "落地签证", price: 58, days: 0, materials: 1, validity: "15天", stay: "15天" },  # ❌ days: 0
  { type: "商务签证", price: 488, days: 5, materials: 5, validity: "90天", stay: "90天" }
]
```

**问题根源**：
- 数据包中 "泰国落地签证" 的 `days: 0`（落地签证即时办理）
- 但 `app/models/visa_product.rb` 第 11 行有验证：
  ```ruby
  validates :processing_days, numericality: { greater_than: 0 }, allow_nil: true
  ```
- 验证要求 `processing_days > 0`，但数据包提供的是 `0`

### 4. 为什么其他 35 条记录没问题？

其他所有签证产品的 `days` 值都 >= 1，满足验证条件，所以 `.save` 成功，slug 正常生成。

## 解决方案

### 修复数据包

将 "泰国落地签证" 的 `days` 从 `0` 改为 `1`（最小有效值）：

```ruby
# app/validators/support/data_packs/v1/visa_services.rb:508
{ type: "落地签证", price: 58, days: 1, materials: 1, validity: "15天", stay: "15天" },  # 落地签证虽然即时办理，但为满足 processing_days > 0 的验证，设为1
```

**理由**：
- 落地签证虽然理论上是即时办理（0 天），但：
  - 实际仍需填写表格、排队等候，有一定时间消耗
  - 设为 1 天更贴近实际情况
  - 满足模型验证要求，避免 slug 生成失败

## 验证结果

### 重新加载数据包

```bash
rake validator:reset_baseline
```

### 验证 slug 覆盖率

```bash
cd /home/runner/app && rails runner "..."
```

**结果**：

```
=== FINAL SLUG COVERAGE VERIFICATION ===

✅ Destination:         0/276 missing (100.0% coverage)
✅ Attraction:          0/773 missing (100.0% coverage)
✅ HotelPackage:        0/17 missing (100.0% coverage)
✅ CruiseLine:          0/3 missing (100.0% coverage)
✅ AbroadBrand:         0/9 missing (100.0% coverage)
✅ Country:             0/28 missing (100.0% coverage)
✅ VisaProduct:         0/36 missing (100.0% coverage)  ← 从 1/36 修复到 0/36
✅ VisaService:         0/13 missing (100.0% coverage)
✅ CharterRoute:        0/252 missing (100.0% coverage)

=== OVERALL: 0/1407 missing (100.0% coverage) ===
```

**成功**：VisaProduct 从 97% 提升到 100% slug 覆盖率！

## 关键教训

### 1. 数据包数据必须满足模型验证

- 使用 `insert_all` 虽然跳过验证，但后续的 `.save` 会触发验证
- 数据包中的数据必须符合模型的 `validates` 规则
- 验证失败会导致 FriendlyId 无法正常生成 slug

### 2. 验证错误与 slug 生成的关系

- FriendlyId 通过 `before_save` 回调生成 slug
- 如果 `.save` 因验证失败而中止，`before_save` 不会执行
- 或者即使执行，验证失败会导致保存失败，slug 不会持久化

### 3. 业务逻辑 vs 数据约束

- "落地签证 0 天" 在业务上合理（即时办理）
- 但数据模型设计时要求 `processing_days > 0`
- 解决方案：调整数据以符合约束，同时保持业务合理性（1 天）

## 相关文件

- **数据包**: `app/validators/support/data_packs/v1/visa_services.rb`
- **模型**: `app/models/visa_product.rb`
- **验证**: Line 11 - `validates :processing_days, numericality: { greater_than: 0 }`

## 时间线

1. **2026-02-04 22:36** - 发现 VisaProduct 有 1/36 缺失 slug
2. **2026-02-04 22:36** - 调查发现 "泰国落地签证" 有验证错误
3. **2026-02-04 22:37** - 修复数据包，将 `days: 0` 改为 `days: 1`
4. **2026-02-04 22:37** - 重新加载数据包
5. **2026-02-04 22:38** - 验证确认 100% slug 覆盖率

## 状态

✅ **已修复** - VisaProduct 现在有 100% slug 覆盖率 (36/36)
