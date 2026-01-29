# V069 & V070 Validator 逻辑优化

## 问题背景

v069 (上海迪士尼家庭套餐) 和 v070 (北京欢乐谷家庭套餐) 验证器在验证订单时存在以下问题：

### 原始场景
- 用户需求：2成人 + 1儿童 的门票
- 系统不支持家庭套票，必须分别购买

### 复杂性
1. **多订单组合**：大模型可能创建多种订单组合
   - 2个订单：1个成人票订单（数量2） + 1个儿童票订单（数量1）
   - 3个订单：1个成人票订单（数量1） + 1个成人票订单（数量1） + 1个儿童票订单（数量1）
   - 或其他组合

2. **干扰订单**：可能存在其他不相关的订单
   - 错误日期的订单
   - 其他票种的订单

### 原始问题
原始验证逻辑在 **断言1** 中就要求：
- `@ticket_orders.size >= 2`：至少2个订单

这种逻辑存在问题：
- ❌ 无法区分 2个订单（每个多张）还是 3个订单（每个1张）
- ❌ 无法处理干扰订单（如果有5个订单，但只有3个是正确日期的）
- ❌ 过早筛选订单，导致后续断言无法验证具体属性

---

## 优化方案

### 核心思路
**分层验证，逐步筛选**：
1. **断言1**：验证是否找到成人票和儿童票订单（不验证数量和日期）
2. **断言2**：验证景点是否正确
3. **断言3**：验证日期是否正确，**并筛选出日期正确的订单**
4. **断言4**：验证成人票**总数量**是否正确（2张，不管几个订单）
5. **断言5**：验证儿童票**总数量**是否正确（1张，不管几个订单）
6. **断言6**：验证价格是否最优（只计算日期正确的订单）

### 详细改动

#### 断言1: 创建了成人票和儿童票订单（20分/25分）

**优化前**：
```ruby
add_assertion "创建了2个订单（成人票订单+儿童票订单）", weight: 20 do
  all_recent_orders = TicketOrder
    .joins(ticket: :attraction)
    .where(tickets: { attractions: { name: @attraction_name } })
    .where(data_version: @data_version)
    .to_a
  
  @ticket_orders = all_recent_orders.select { |o| ['adult', 'child'].include?(o.ticket.ticket_type) }
  
  expect(@ticket_orders.size).to be >= 2  # ❌ 过早验证订单数量
  
  @adult_orders = @ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
  @child_orders = @ticket_orders.select { |o| o.ticket.ticket_type == 'child' }
end
```

**优化后**：
```ruby
add_assertion "创建了成人票和儿童票订单", weight: 20 do
  all_orders = TicketOrder
    .joins(ticket: :attraction)
    .where(tickets: { attractions: { name: @attraction_name } })
    .where(data_version: @data_version)
    .to_a
  
  # 只保留成人票和儿童票订单（排除其他类型）
  @all_ticket_orders = all_orders.select { |o| ['adult', 'child'].include?(o.ticket.ticket_type) }
  
  # 只验证是否存在成人票和儿童票订单，不验证数量
  all_adult_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
  all_child_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'child' }
  
  expect(all_adult_orders).not_to be_empty  # ✅ 只验证存在性
  expect(all_child_orders).not_to be_empty
end
```

#### 断言3: 游玩日期正确（10分） - 调整顺序

**优化前**（断言5）：
```ruby
add_assertion "游玩日期正确（后天，#{@visit_date}）", weight: 10 do
  @ticket_orders.each do |order|
    expect(order.visit_date).to eq(@visit_date)  # ❌ 验证所有订单，包括干扰订单
  end
end
```

**优化后**（断言3，提前到数量验证之前）：
```ruby
add_assertion "游玩日期正确（后天，#{@visit_date}）", weight: 10 do
  # 筛选出日期正确的订单
  @correct_date_orders = @all_ticket_orders.select { |o| o.visit_date == @visit_date }
  
  expect(@correct_date_orders).not_to be_empty,
    "未找到日期为#{@visit_date}（后天）的订单。" \
    "找到的订单日期为: #{@all_ticket_orders.map(&:visit_date).uniq.join(', ')}"
  
  # 分离成人票和儿童票（日期正确的）
  @adult_orders = @correct_date_orders.select { |o| o.ticket.ticket_type == 'adult' }
  @child_orders = @correct_date_orders.select { |o| o.ticket.ticket_type == 'child' }
  
  expect(@adult_orders).not_to be_empty
  expect(@child_orders).not_to be_empty
end
```

**关键改进**：
- ✅ 先验证日期，筛选出日期正确的订单
- ✅ 后续断言只验证日期正确的订单
- ✅ 自动过滤掉干扰订单

#### 断言4/5: 成人票/儿童票数量正确（15分/10分）

**优化前**：
```ruby
add_assertion "成人票数量正确（2张）", weight: 15 do
  expect(@actual_adult_count).to eq(@adult_count)  # @actual_adult_count 在断言1中已计算
end
```

**优化后**：
```ruby
add_assertion "成人票数量正确（2张）", weight: 15 do
  actual_adult_count = @adult_orders.sum(&:quantity)  # ✅ 动态计算，支持多订单组合
  
  expect(actual_adult_count).to eq(@adult_count),
    "成人票总数量错误。期望: 2张, 实际: #{actual_adult_count}张 " \
    "（来自#{@adult_orders.size}个订单: #{@adult_orders.map { |o| \"#{o.quantity}张\" }.join(' + ')}）"
end
```

**关键改进**：
- ✅ 验证**总数量**而不是订单数量
- ✅ 支持多订单组合：
  - 1个订单2张 ✅
  - 2个订单各1张 ✅
  - 任意组合只要总数是2张 ✅
- ✅ 错误信息显示订单组合详情

#### 断言6: 选择了最优惠的供应商组合（25分/30分）

**优化前**：
```ruby
add_assertion "选择了最优惠的供应商组合", weight: 25 do
  actual_total = @adult_orders.sum(&:total_price) + @child_orders.sum(&:total_price)  # 包含所有日期的订单
  # ...
end
```

**优化后**：
```ruby
add_assertion "选择了最优惠的供应商组合", weight: 25 do
  # 只计算日期正确的订单
  actual_total = @adult_orders.sum(&:total_price) + @child_orders.sum(&:total_price)
  
  best_total = @best_adult_price * @adult_count + @best_child_price * @child_count
  
  expect(actual_total).to be <= (best_total * 1.05),
    "未选择最优惠的供应商组合。" \
    "最优方案总价: #{best_total.round(2)}元（成人#{@best_adult_price}元×2 + 儿童#{@best_child_price}元×1），" \
    "实际总价: #{actual_total.round(2)}元（成人票: #{@adult_orders.sum(&:total_price).round(2)}元 + 儿童票: #{@child_orders.sum(&:total_price).round(2)}元）"
end
```

---

## 优化效果

### 支持的场景

#### ✅ 场景1: 标准场景 - 2个订单
- 订单1: 成人票 × 2张
- 订单2: 儿童票 × 1张
- **结果**: 通过 ✅ (100分)

#### ✅ 场景2: 多订单组合 - 3个订单
- 订单1: 成人票 × 1张
- 订单2: 成人票 × 1张
- 订单3: 儿童票 × 1张
- **结果**: 通过 ✅ (100分)

#### ✅ 场景3: 有干扰订单
- 订单1: 成人票 × 2张（日期：后天） ✅
- 订单2: 儿童票 × 1张（日期：后天） ✅
- 订单3: 成人票 × 1张（日期：3天后） ❌ 被自动过滤
- **结果**: 通过 ✅ (100分，只验证日期正确的订单)

### 错误信息改进

**优化前**：
```
订单数量不足。期望至少2个订单（1个成人票订单+1个儿童票订单），实际找到3个订单
```
- ❌ 无法区分是3个正确订单还是2个正确+1个干扰
- ❌ 误报：3个订单（1+1+1）应该是正确的

**优化后**：
```
成人票总数量错误。期望: 2张, 实际: 3张 （来自3个订单: 1张 + 1张 + 1张）
```
- ✅ 明确指出总数量错误
- ✅ 显示订单组合详情
- ✅ 不关心订单数量，只关心总数量

---

## 实现文件

- `app/validators/v069_book_shanghai_disney_family_tickets_validator.rb`
- `app/validators/v070_book_beijing_happy_valley_family_tickets_validator.rb`

## 测试验证

运行全量 validator 测试：
```bash
rake validator:simulate
```

**结果**：
- v069: ✅ PASSED (100/100)
- v070: ✅ PASSED (100/100)
- 全部97个 validators: ✅ All passed

---

## 总结

### 核心优化原则

1. **分层验证**：不要在一个断言中验证多个属性
2. **逐步筛选**：先验证存在性 → 验证日期 → 验证数量 → 验证价格
3. **验证总量**：验证票的总数量而不是订单数量
4. **过滤干扰**：通过日期筛选，自动过滤掉干扰订单
5. **详细错误信息**：显示订单组合详情，便于调试

### 适用场景

这种优化模式适用于所有需要验证"多个订单组合满足总量要求"的场景，例如：
- 家庭套餐订票（2成人+1儿童）
- 团体票订购（10个成人+5个儿童）
- 多人酒店预订（3间房，可能分3个订单）
- 多程机票（往返票可能是2个订单）

### 最佳实践

1. **查询阶段**：只按 `data_version` + 核心业务实体（景点名、酒店名）筛选
2. **断言1**：验证是否找到了相关订单类型
3. **断言2**：验证业务实体是否正确
4. **断言3**：验证并筛选关键属性（日期、类型等），建立 guard clause
5. **断言4-N**：验证具体数量、价格等（只对筛选后的订单）

遵循这个模式，validator 可以准确处理各种复杂的多订单组合场景。
