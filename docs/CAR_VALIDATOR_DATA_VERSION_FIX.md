# 租车验证器 data_version 过滤和 pickup_date 验证修复

## 问题描述

在租车验证器（CarOrder validators）中发现了两类常见问题：

### 问题1：缺少 data_version 过滤（高优先级）
**影响范围：** 7个验证器
**问题根源：** 第一个断言查询订单时使用 `CarOrder.order(created_at: :desc).first`，没有加 `.where(data_version: @data_version)` 过滤

**为什么这是严重问题：**
- 没有 data_version 过滤会导致验证器查询到其他会话的订单
- 违反了多会话隔离原则（参见 `docs/MULTI_SESSION_IMPLEMENTATION.md`）
- 可能导致验证器误判（验证了别的会话创建的订单）

### 问题2：缺少取车日期（pickup_date）验证（中优先级）
**影响范围：** 3个验证器（v033, v035, v036）
**问题根源：** 虽然任务描述中明确了取车日期（"后天"或"明天"），但 verify 方法中没有断言验证这个条件

**为什么需要验证取车日期：**
- 任务标题中明确了时间要求（"后天北京SUV"）
- 如果不验证日期，AI可能创建任意日期的订单也能通过
- 缺少这个断言会降低验证器的准确性

---

## 修复的验证器列表

| 验证器 ID | 验证器名称 | 问题类型 | 修复内容 |
|-----------|-----------|---------|---------|
| v005 | book_economy_car_validator | ❌ data_version | ✅ 添加 data_version 过滤 |
| v013 | search_family_car_validator | ❌ data_version | ✅ 添加 data_version 过滤 |
| v032 | rent_any_car_shanghai_validator | ❌ data_version | ✅ 添加 data_version 过滤 |
| v033 | rent_suv_beijing_validator | ❌ data_version<br>❌ pickup_date | ✅ 添加 data_version 过滤<br>✅ 添加 pickup_date 断言 |
| v034 | rent_cheapest_car_shenzhen_validator | ❌ data_version | ✅ 添加 data_version 过滤 |
| v035 | rent_luxury_car_guangzhou_validator | ❌ data_version<br>❌ pickup_date | ✅ 添加 data_version 过滤<br>✅ 添加 pickup_date 断言 |
| v036 | rent_business_van_hangzhou_validator | ❌ data_version<br>❌ pickup_date | ✅ 添加 data_version 过滤<br>✅ 添加 pickup_date 断言 |

---

## 修复前后对比

### 修复前（错误模式）
```ruby
def verify
  add_assertion "订单已创建", weight: 20 do
    @order = CarOrder.order(created_at: :desc).first  # ❌ 没有 data_version 过滤
    expect(@order).not_to be_nil, "未找到任何租车订单记录"
  end

  return unless @order

  add_assertion "城市正确（北京）", weight: 20 do
    expect(@order.car.location).to eq(@location)
  end

  # ❌ 缺少取车日期验证

  add_assertion "车型正确（SUV）", weight: 30 do
    expect(@order.car.category).to eq(@category)
  end

  add_assertion "租赁天数正确（2天）", weight: 30 do
    # ...
  end
end
```

### 修复后（正确模式）
```ruby
def verify
  add_assertion "订单已创建", weight: 15 do
    all_orders = CarOrder
      .where(data_version: @data_version)  # ✅ 添加 data_version 过滤
      .order(created_at: :desc)
      .to_a
    
    expect(all_orders).not_to be_empty, "未找到任何租车订单记录"
    @order = all_orders.first
  end

  return unless @order

  add_assertion "城市正确（北京）", weight: 15 do
    expect(@order.car.location).to eq(@location)
  end

  # ✅ 添加取车日期验证
  add_assertion "取车日期正确（后天 #{@pickup_date.strftime('%Y-%m-%d')}）", weight: 15 do
    pickup_date = @order.pickup_datetime.to_date
    expect(pickup_date).to eq(@pickup_date),
      "取车日期不正确。期望: #{@pickup_date}（后天）, 实际: #{pickup_date}"
  end

  add_assertion "车型正确（SUV）", weight: 25 do
    expect(@order.car.category).to eq(@category),
      "车型不正确。期望: #{@category}, 实际: #{@order.car.category}"
  end

  add_assertion "租赁天数正确（2天）", weight: 30 do
    # ...
  end
end
```

---

## 权重调整说明

为添加 pickup_date 断言腾出权重，调整了部分断言的权重分配：

### v033, v035, v036（需要添加 pickup_date 断言的验证器）

**调整前：**
- 订单已创建：20%
- 城市正确：20%
- 车型正确：30%
- 租赁天数/座位数：30%
- **总计：100%**

**调整后：**
- 订单已创建：15% ↓5%
- 城市正确：15% ↓5%
- **取车日期正确：15% ✨新增**
- 车型正确：25% ↓5%
- 租赁天数/座位数：30% （不变）
- **总计：100%**

### v005, v013, v032, v034（已有 pickup_date 断言的验证器）

**无需调整权重：** 这些验证器本身已经有取车日期验证，只需添加 data_version 过滤即可。

---

## 测试验证

所有修复的验证器均通过单元测试：

```bash
✓ v005_book_economy_car_validator         (100/100)
✓ v013_search_family_car_validator        (100/100)
✓ v032_rent_any_car_shanghai_validator    (100/100)
✓ v033_rent_suv_beijing_validator         (100/100)  ← 修复了 2 个问题
✓ v034_rent_cheapest_car_shenzhen_validator (100/100)
✓ v035_rent_luxury_car_guangzhou_validator (100/100)  ← 修复了 2 个问题
✓ v036_rent_business_van_hangzhou_validator (100/100) ← 修复了 2 个问题
```

---

## 技术要点

### 1. data_version 查询模式（MANDATORY）

**正确模式：**
```ruby
all_orders = CarOrder
  .where(data_version: @data_version)  # ✅ 必须添加
  .order(created_at: :desc)
  .to_a

expect(all_orders).not_to be_empty, "未找到任何租车订单记录"
@order = all_orders.first
```

**为什么使用 `.to_a` 而不是 `.first`：**
- 先过滤出当前会话的所有订单
- 再检查是否为空（更清晰的错误信息）
- 最后取第一个订单

### 2. 取车日期验证模式

**标准模式：**
```ruby
add_assertion "取车日期正确（后天 #{@pickup_date.strftime('%Y-%m-%d')}）", weight: 15 do
  pickup_date = @order.pickup_datetime.to_date
  expect(pickup_date).to eq(@pickup_date),
    "取车日期不正确。期望: #{@pickup_date}（后天）, 实际: #{pickup_date}"
end
```

**关键点：**
- `@order.pickup_datetime.to_date`：从 datetime 转换为 date 进行比较
- 错误消息中包含期望值和实际值
- 错误消息中使用中文描述（"后天"、"明天"）增强可读性

---

## 相关文档

- **多会话数据隔离：** `docs/MULTI_SESSION_IMPLEMENTATION.md`
- **验证器设计规范：** `docs/VALIDATOR_DESIGN.md`
- **验证器 verify 方法最佳实践：** `.clackyrules` 中的 "Validator verify Method Best Practices"

---

## 经验教训

### 1. 第一个断言必须包含 data_version 过滤
这是多会话隔离的基础要求，没有它验证器会查询到其他会话的数据。

### 2. 任务描述中的时间要求必须有对应的断言
如果标题写了"后天"或"明天"，verify 方法中必须验证 pickup_date。

### 3. 断言权重需要合理分配
- 订单存在性：15-20%
- 核心实体（城市、车型）：15-25%
- 时间条件（取车日期、租赁天数）：10-30%
- 业务逻辑（价格、座位数）：20-40%

### 4. 错误消息要具体且有帮助
- ❌ "日期错误"
- ✅ "取车日期不正确。期望: 2026-02-10（后天）, 实际: 2026-02-11"

---

## 修复日期

**修复时间：** 2026-02-08

**修复原因：** 用户反馈 v033_rent_suv_beijing_validator 缺少取车时间（标题里面写明的是后天）验证，排查发现多个验证器有类似问题

**影响范围：** 7个租车验证器（v005, v013, v032, v033, v034, v035, v036）

**修复状态：** ✅ 已完成并测试通过
