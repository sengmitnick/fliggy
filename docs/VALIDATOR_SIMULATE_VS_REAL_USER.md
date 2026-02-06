# Validator Simulate Method vs Real User Experience

## 📋 问题概述

**问题ID**: V259 门票供应商缺失问题  
**发现日期**: 2026-02-06  
**影响范围**: 所有依赖第三方服务（供应商、库存等）的验证器

## 🐛 问题描述

验证器 V259 (`v259_book_high_risk_activity_with_insurance_validator`) 的测试通过了（100/100），但实际用户无法完成任务。

### 根本原因

**测试通过 ≠ 用户可用**

验证器的 `simulate()` 方法直接创建了订单记录，**绕过了真实用户必须经过的业务流程**：

```ruby
# ❌ simulate() 直接创建订单（测试能通过）
ticket_order = TicketOrder.create!(
  user: user,
  ticket: @ticket,
  visit_date: @visit_date,
  quantity: @quantity,
  total_price: @ticket.current_price * @quantity,
  status: 'paid',
  data_version: @data_version
)
```

**真实用户流程**：
1. 访问景点页面 `/attractions/:slug`
2. 点击门票购买
3. 选择票种 `/tickets/:id/select`
4. **选择供应商** `/tickets/:id/suppliers` ← **这一步失败了！**
5. 确认订单
6. 支付

**问题点**：
- 门票(ticket_id=37) 没有关联任何 `TicketSupplier` 记录
- 用户访问 `/tickets/37/suppliers` 页面时，查询结果为空
- 前端无法显示供应商列表，用户无法进入下一步
- **但 simulate() 绕过了供应商选择，直接创建订单，测试通过！**

### 实际错误日志

```
GET /tickets/37/suppliers?visit_date=2026-02-14&ticket_id=37

TicketSupplier Load (0.3ms)  SELECT "ticket_suppliers".* 
FROM "ticket_suppliers" 
WHERE "ticket_suppliers"."ticket_id" = 37
-- 返回空结果

Rendered tickets/suppliers.html.erb
-- 页面显示"暂无供应商"，用户无法购买
```

## 🔍 问题分析

### 1. 数据包问题

**文件**: `app/validators/support/data_packs/v1/seasonal_events.rb`

```ruby
# ✅ 创建了门票
tickets_data << {
  attraction_id: cl_attraction.id,
  ticket_type: "adult",
  name: "崇礼万龙滑雪场全天票",
  price: 380.0,
  # ...
  data_version: 0
}

# ❌ 但没有创建 TicketSupplier 关联
# 导致门票无法销售
```

**对比正确的数据包** (`attractions.rb`):

```ruby
# 1. 创建门票
tickets_data << { name: "深圳欢乐港湾成人票", ... }

# 2. 创建供应商关联
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 85,
  stock: 500,
  # ...
}
```

### 2. Simulate 方法设计缺陷

**当前设计问题**：

| 方面 | simulate() | 真实用户 |
|------|-----------|---------|
| 订单创建 | 直接 `Model.create!()` | 通过 Controller + Service |
| 供应商检查 | ❌ 跳过 | ✅ 必须选择供应商 |
| 库存验证 | ❌ 跳过 | ✅ 检查库存 |
| 价格计算 | ❌ 手动计算 | ✅ 业务逻辑计算 |
| 数据完整性 | ❌ 可能缺失关联数据 | ✅ 依赖完整数据 |

**结果**：
- ✅ 测试通过：simulate() 绕过所有检查，直接创建订单
- ❌ 用户失败：缺少供应商数据，无法进入购买流程

## 🛠️ 解决方案

### 方案 1: 修复数据包（已实施）

**文件**: `app/validators/support/data_packs/v1/seasonal_events.rb`

```ruby
# ==================== 门票供应商关联数据 ====================
puts "  创建门票供应商关联数据..."

# 重新加载供应商以获取 ID（attractions.rb 中已创建）
suppliers = {}
Supplier.where(data_version: 0).each do |supplier|
  suppliers[supplier.name] = supplier
end

# 崇礼万龙滑雪场全天票 - 3个供应商
cl_ticket = Ticket.joins(:attraction).find_by(
  attractions: { name: "崇礼万龙滑雪场" },
  ticket_type: "adult",
  data_version: 0
)

if cl_ticket && suppliers.any?
  ticket_suppliers_data = []
  
  # 携程旅行供应商
  if suppliers["携程旅行"]
    ticket_suppliers_data << {
      ticket_id: cl_ticket.id,
      supplier_id: suppliers["携程旅行"].id,
      current_price: 360,
      original_price: 450,
      stock: 300,
      discount_info: "滑雪季早鸟价",
      sales_count: 1580,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 美团门票供应商
  if suppliers["美团门票"]
    ticket_suppliers_data << {
      ticket_id: cl_ticket.id,
      supplier_id: suppliers["美团门票"].id,
      current_price: 365,
      original_price: 450,
      stock: 200,
      discount_info: "限时特惠",
      sales_count: 980,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 景区官方供应商
  if suppliers["景区官方"]
    ticket_suppliers_data << {
      ticket_id: cl_ticket.id,
      supplier_id: suppliers["景区官方"].id,
      current_price: 380,
      original_price: 450,
      stock: -1,
      discount_info: nil,
      sales_count: 2560,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  TicketSupplier.insert_all(ticket_suppliers_data) if ticket_suppliers_data.any?
  puts "    ✓ 创建了 #{ticket_suppliers_data.size} 个门票供应商关联"
end
```

**验证结果**：

```bash
$ rails runner "ticket = Ticket.find(37); puts TicketSupplier.where(ticket_id: ticket.id).count"
3  # ✅ 3个供应商

$ rails runner "TicketSupplier.where(ticket_id: 37).each { |ts| puts Supplier.find(ts.supplier_id).name }"
携程旅行
美团门票
景区官方
```

### 方案 2: 优化 Simulate 方法（推荐）

**核心原则**：**Simulate 应该模拟真实用户行为，而非直接创建数据**

#### Before（当前问题代码）:

```ruby
def simulate
  user = User.find_by(email: '[FILTERED]', data_version: @data_version)
  
  # ❌ 直接创建订单，绕过业务逻辑
  ticket_order = TicketOrder.create!(
    user: user,
    ticket: @ticket,
    visit_date: @visit_date,
    quantity: @quantity,
    total_price: @ticket.current_price * @quantity,
    status: 'paid',
    data_version: @data_version
  )
  
  activity_order = ActivityOrder.create!(...)
  insurance_order = InsuranceOrder.create!(...)
  
  insurance_order
end
```

**问题**：
1. 没有检查 TicketSupplier 是否存在
2. 没有验证供应商库存
3. 没有选择最优供应商
4. 绕过了真实用户必须经过的流程

#### After（优化后代码）:

```ruby
def simulate
  user = User.find_by(email: '[FILTERED]', data_version: @data_version)
  
  # ✅ Step 1: 检查门票是否有供应商（模拟用户访问 /tickets/:id/suppliers）
  available_suppliers = TicketSupplier
    .where(ticket_id: @ticket.id, data_version: @data_version)
    .where('stock > 0 OR stock = -1')
  
  raise "门票无供应商，用户无法购买（/tickets/#{@ticket.id}/suppliers 返回空）" if available_suppliers.empty?
  
  # ✅ Step 2: 选择最便宜的供应商（模拟用户选择）
  cheapest_supplier = available_suppliers.order(:current_price).first
  
  # ✅ Step 3: 使用供应商价格创建订单（模拟真实业务逻辑）
  ticket_order = TicketOrder.create!(
    user: user,
    ticket: @ticket,
    ticket_supplier_id: cheapest_supplier.id,  # 关联供应商
    visit_date: @visit_date,
    quantity: @quantity,
    total_price: cheapest_supplier.current_price * @quantity,  # 使用供应商价格
    status: 'paid',
    data_version: @data_version
  )
  
  # ✅ Step 4: 创建活动订单
  activity_order = ActivityOrder.create!(
    user: user,
    attraction_activity: @activity,
    visit_date: @visit_date,
    quantity: @quantity,
    total_price: @activity.current_price * @quantity,
    insurance_type: 'none',
    status: 'paid',
    data_version: @data_version
  )
  
  # ✅ Step 5: 查找合适的保险产品
  insurance_product = InsuranceProduct
    .where(data_version: @data_version)
    .where("insurance_type = ? AND coverage_scope LIKE ?", 'sports', '%滑雪%')
    .first
  
  raise "未找到包含滑雪场景的运动保险产品" unless insurance_product
  
  # ✅ Step 6: 创建保险订单
  insurance_order = InsuranceOrder.create!(
    user: user,
    insurance_product: insurance_product,
    start_date: @visit_date,
    end_date: @visit_date,
    coverage_days: 1,
    total_price: insurance_product.price_per_day * 1,
    status: 'paid',
    data_version: @data_version
  )
  
  insurance_order
end
```

**优化效果**：

| 检查项 | Before | After |
|--------|--------|-------|
| 供应商存在性 | ❌ 不检查 | ✅ 检查，无供应商则报错 |
| 供应商库存 | ❌ 不检查 | ✅ 检查 `stock > 0 OR stock = -1` |
| 价格来源 | ❌ 直接用 ticket.price | ✅ 用 supplier.current_price |
| 关联供应商 | ❌ 无关联 | ✅ 记录 ticket_supplier_id |
| 错误提示 | ❌ 测试通过，用户失败 | ✅ 测试失败，提示缺失数据 |

## 📊 测试对比

### Before（修复前）:

```bash
$ rake validator:simulate_single[v259_book_high_risk_activity_with_insurance_validator]

✅ PASSED (100/100)
# 但用户访问 /tickets/37/suppliers 看到空页面
```

### After（修复后）:

```bash
# 1. 如果数据包缺失供应商
$ rake validator:simulate_single[v259_book_high_risk_activity_with_insurance_validator]

❌ FAILED
Error: 门票无供应商，用户无法购买（/tickets/37/suppliers 返回空）
# ✅ 测试失败，提示开发者修复数据包

# 2. 数据包完整后
$ rake validator:simulate_single[v259_book_high_risk_activity_with_insurance_validator]

✅ PASSED (100/100)
# ✅ 测试通过，用户也能正常使用
```

## 📝 最佳实践

### 1. 数据包完整性检查清单

创建新的数据包时，必须检查：

- [ ] **主表记录**：基础数据是否创建？
- [ ] **关联表记录**：是否创建了必要的关联？
  - [ ] TicketSupplier（门票供应商）
  - [ ] HotelRoom（酒店房型）
  - [ ] FlightOffer（航班优惠）
  - [ ] TrainSeat（火车座位）
  - [ ] 等等...
- [ ] **库存数据**：stock 字段是否设置？
- [ ] **价格数据**：current_price 是否合理？
- [ ] **状态数据**：is_active, status 等是否正确？

### 2. Simulate 方法设计原则

**核心原则**：**Simulate = 模拟真实用户操作流程**

```ruby
def simulate
  # ✅ DO: 检查必要的前置条件
  raise "缺少供应商数据" if suppliers.empty?
  raise "库存不足" if stock <= 0
  
  # ✅ DO: 使用业务逻辑计算价格
  price = calculate_price_with_discount(supplier)
  
  # ✅ DO: 记录完整的关联关系
  order.update!(supplier_id: supplier.id)
  
  # ❌ DON'T: 绕过业务逻辑直接创建数据
  Order.create!(status: 'paid')  # BAD
  
  # ❌ DON'T: 手动计算应该由业务逻辑处理的数据
  total = price * quantity  # BAD（应该调用 service）
end
```

### 3. 验证器开发流程

```
1. 设计验证器
   ↓
2. 检查数据包完整性（手动验证关键关联表）
   ↓
3. 编写 prepare() 方法
   ↓
4. 编写 simulate() 方法（模拟真实用户流程）
   ↓
5. 编写 verify() 方法
   ↓
6. 运行测试：rake validator:simulate_single[validator_id]
   ↓
7. 手动测试：浏览器访问相关页面，验证用户体验
   ↓
8. 提交代码
```

**第 7 步是关键**：必须手动验证用户能否完成任务！

### 4. 常见陷阱

| 陷阱 | 说明 | 检测方法 |
|------|------|---------|
| 缺少供应商 | 门票/酒店/车辆无供应商 | 访问 `/xxx/suppliers` 页面 |
| 缺少房型 | 酒店无房型 | 访问酒店详情页 |
| 缺少座位 | 火车/飞机无座位 | 尝试预订 |
| 库存为0 | stock=0 导致无法购买 | 检查库存字段 |
| 价格错误 | current_price 为 nil 或 0 | 检查价格显示 |
| 日期过期 | 数据包日期已过期 | 检查 Date.today 范围 |

## 🔗 相关文档

- [Data Packs 管理指南](DATA_PACKS.md)
- [Validator 开发规范](VALIDATOR_DEVELOPMENT.md)
- [数据包文件组织规则](.clackyrules#data-packs)

## 🏷️ 标签

`validator` `data-pack` `simulate-method` `ticket-supplier` `bug-fix` `best-practice`

---

**总结**：验证器测试通过 ≠ 用户可用。Simulate 方法必须模拟真实用户流程，检查所有必要的前置条件和关联数据，而不是简单地绕过业务逻辑直接创建订单。数据包必须包含完整的关联数据（如 TicketSupplier），否则用户无法完成任务。
