# V070 验证器优化总结

## 📋 优化目标

根据 `docs/VALIDATOR_WRITING_STANDARDS.md` 文档，优化 v070 验证器（给张三一家预订北京欢乐谷门票）。

---

## ✅ 优化内容

### 1. **标题格式优化**

**优化前：**
```ruby
title = '预订3天后北京欢乐谷家庭套餐（2成人+1儿童，最便宜）'
```

**优化后：**
```ruby
title = '给张三一家预订3天后北京欢乐谷门票（张三、王芳、小明，最便宜）'
```

**原因：**
- ❌ 抽象描述："2成人+1儿童"
- ✅ 具体姓名："张三、王芳、小明"
- 符合文档规范：家庭门票应明确列出成员姓名

---

### 2. **描述格式优化**

**优化前：**
```ruby
description = '为1个家庭预订欢乐谷门票（2成人+1儿童），通过2个订单实现，选择最便宜的供应商'
```

**优化后：**
```ruby
description = '为张三一家（张三、王芳、小明）预订欢乐谷门票，通过2个订单实现，选择最便宜的供应商'
```

**原因：**
- 明确列出家庭成员，增强任务可读性

---

### 3. **prepare 方法增强 - 查询家庭成员**

**新增代码：**
```ruby
# 查询家庭成员（张三一家）
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
@zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
@wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
@xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)

@expected_contact_phone = @zhangsan.phone
@expected_passenger_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
```

**原因：**
- 在 prepare 中预查询游客信息（避免 simulate 中使用 `data_version: 0`）
- 为后续验证提供期望值

---

### 4. **simulate 方法优化 - 使用真实游客数据**

**优化前：**
```ruby
adult_order = TicketOrder.create!(
  # ...
  contact_phone: '13800138000',  # ❌ 硬编码电话
  visit_date: @visit_date,
  quantity: @adult_count,
  # ❌ 缺少 passenger_ids
  # ❌ 缺少 data_version
)
```

**优化后：**
```ruby
adult_order = TicketOrder.create!(
  # ...
  contact_phone: @expected_contact_phone,        # ✅ 使用真实数据
  passenger_ids: [@zhangsan.id, @wangfang.id],   # ✅ 关联游客
  visit_date: @visit_date,
  quantity: @adult_count,
  data_version: @data_version                     # ✅ 会话隔离
)

child_order = TicketOrder.create!(
  # ...
  contact_phone: @expected_contact_phone,
  passenger_ids: [@xiaoming.id],                  # ✅ 关联儿童
  visit_date: @visit_date,
  quantity: @child_count,
  data_version: @data_version
)
```

**原因：**
- ✅ 使用 demo_user 数据（张三的真实电话：13800138000）
- ✅ 通过 `passenger_ids` 关联游客
- ✅ 添加 `data_version` 确保会话隔离

---

### 5. **verify 方法增强 - 新增游客信息验证**

**新增断言（合计 20 分）：**

#### 断言6: 联系人信息正确（10分）
```ruby
add_assertion "联系人信息正确（#{@expected_contact_phone}）", weight: 10 do
  [@adult_orders, @child_orders].flatten.each do |order|
    expect(order.contact_phone).to eq(@expected_contact_phone),
      "联系人电话错误。期望: #{@expected_contact_phone}（张三），实际: #{order.contact_phone}"
  end
end
```

#### 断言7: 游客信息正确（10分）
```ruby
add_assertion "游客信息正确（张三、王芳、小明）", weight: 10 do
  # 收集所有订单的 passenger_ids
  all_passenger_ids = (@adult_orders + @child_orders).flat_map { |o| o.passenger_ids || [] }.compact.uniq
  
  expect(all_passenger_ids).not_to be_empty,
    "订单中未关联任何游客信息（passenger_ids 为空）"
  
  # 查询关联的游客
  actual_passengers = Passenger.where(id: all_passenger_ids, data_version: 0)
  actual_names = actual_passengers.pluck(:name).sort
  
  expect(actual_names).to match_array(@expected_passenger_names.sort),
    "游客名单错误。期望: #{@expected_passenger_names.sort.join('、')}，实际: #{actual_names.join('、')}"
end
```

**原因：**
- 验证联系人电话正确（张三的电话）
- 验证订单关联的游客正确（张三、王芳、小明）
- 符合文档规范：家庭门票需要验证联系人（10分）+ 游客信息（10分）

---

### 6. **权重分配调整**

**优化前：**
```
创建订单: 25
景点正确: 15
成人数量: 10
儿童数量: 10
游玩日期: 10
最优价格: 30
总计: 100
```

**优化后：**
```
创建订单: 20
景点正确: 15
成人数量: 10
儿童数量: 10
游玩日期: 5
联系人信息: 10  ← 新增
游客信息: 10    ← 新增
最优价格: 20
总计: 100
```

**调整原因：**
- 为新增的联系人和游客信息验证腾出 20 分
- 从"创建订单"（25→20）、"游玩日期"（10→5）、"最优价格"（30→20）中调整

---

### 7. **N+1 查询优化**

**优化前：**
```ruby
all_orders = TicketOrder
  .joins(ticket: :attraction)
  .includes(:ticket)  # ❌ 只预加载 ticket，没有预加载 attraction
  .where(...)
```

**优化后：**
```ruby
all_orders = TicketOrder
  .joins(ticket: :attraction)
  .includes(ticket: :attraction)  # ✅ 同时预加载 ticket 和 attraction
  .where(...)
```

**原因：**
- 避免在循环中访问 `order.ticket.attraction` 时触发 N+1 查询

---

### 8. **状态管理完善**

**新增字段保存/恢复：**
```ruby
def execution_state_data
  {
    # ... 原有字段
    expected_contact_phone: @expected_contact_phone,
    expected_passenger_names: @expected_passenger_names
  }
end

def restore_from_state(data)
  # ... 原有字段
  @expected_contact_phone = data['expected_contact_phone']
  @expected_passenger_names = data['expected_passenger_names']
end
```

**原因：**
- 确保 verify 阶段可以正确恢复期望值

---

## 📊 测试结果

### ✅ 所有检查通过

```bash
rake validator:simulate_single[v070_book_beijing_happy_valley_family_tickets_validator]
```

**结果：**
- ✅ Step 1: validator_id 格式正确
- ✅ Step 2: 状态管理方法完整
- ✅ Step 3: 状态字段一致性
- ✅ Step 4: prepare 无数据创建违规
- ✅ Step 5: simulate 无 data_version: 0 违规
- ✅ Step 6: 权重总和 = 100

### ✅ 模拟测试通过（100/100）

**8个断言全部通过：**
1. ✅ 创建了成人票和儿童票订单 (20分)
2. ✅ 景点正确（北京欢乐谷）(15分)
3. ✅ 游玩日期正确（3天后，2026-02-12）(5分)
4. ✅ 成人票数量正确（2张）(10分)
5. ✅ 儿童票数量正确（1张）(10分)
6. ✅ 联系人信息正确（13800138000）(10分)
7. ✅ 游客信息正确（张三、王芳、小明）(10分)
8. ✅ 选择了最优惠的供应商组合 (20分)

---

## 📝 关键改进点总结

1. **✅ 标题/描述使用具体家庭成员姓名**（符合文档第一条规范）
2. **✅ prepare 中预查询游客信息**（避免 simulate 中使用 data_version: 0）
3. **✅ simulate 中使用真实 demo_user 数据**（电话 + passenger_ids）
4. **✅ verify 新增联系人和游客信息验证**（合计 20 分）
5. **✅ 权重分配调整为 100 分**（原为 110 分）
6. **✅ 修复 N+1 查询问题**（预加载 attraction 关联）
7. **✅ 状态管理完善**（保存/恢复期望值）

---

## 📚 参考文档

- `docs/VALIDATOR_WRITING_STANDARDS.md` - 验证器编写标准
- `app/validators/support/data_packs/v1/demo_user.rb` - Demo 用户数据

---

## 🎯 优化前后对比

| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 标题 | "预订...家庭套餐（2成人+1儿童）" | "给张三一家预订...（张三、王芳、小明）" |
| 联系人验证 | ❌ 缺失 | ✅ 10分 |
| 游客信息验证 | ❌ 缺失 | ✅ 10分 |
| 硬编码电话 | ❌ '13800138000' | ✅ @expected_contact_phone |
| passenger_ids | ❌ 缺失 | ✅ 关联张三、王芳、小明 |
| data_version | ❌ 缺失 | ✅ @data_version |
| N+1 查询 | ⚠️ 存在 | ✅ 已优化 |
| 权重总和 | ⚠️ 110分 | ✅ 100分 |

---

**优化完成时间：** 2024年
**验证器 ID：** v070_book_beijing_happy_valley_family_tickets_validator
**测试状态：** ✅ 全部通过（100/100）
