# v010 验证器优化总结

## 📋 优化目标
根据 `docs/VALIDATOR_WRITING_STANDARDS.md` 标准，优化 v010_search_cheapest_flight_validator 验证器。

---

## ✅ 优化内容

### 1. 题目格式优化 ✨

**问题：** 原题目缺少受益人，像查询任务而不是服务请求

**修改前：**
```
标题：搜索上海到深圳的最便宜航班套餐（后天1人）
描述：搜索后天上海到深圳的所有航班套餐，找出最终成本最低的并完成预订（考虑返现，1人出行）
```

**修改后：**
```
标题：给张三订后天去深圳的机票（选最便宜的经济舱）
描述：给张三预订后天从上海到深圳的经济舱机票，找出最终成本最低的航班套餐并完成预订（考虑返现）
```

**改进点：**
- ✅ 遵循 `给/帮 [受益人] + 动词 + 核心目标 + （关键约束）` 格式
- ✅ 包含受益人"张三"
- ✅ 更符合用户自然语言表达习惯
- ✅ 移除操作步骤细节（"1人出行"改为隐含信息）

---

### 2. 验证断言逻辑优化 🔍

#### 问题1：第一条断言查询不够精确

**修改前：**
```ruby
add_assertion "订单已创建", weight: 20 do
  @booking = Booking.where(data_version: @data_version).order(created_at: :desc).first
  expect(@booking).not_to be_nil, "未找到任何订单记录"
end
```

**问题：**
- ❌ 只过滤了 `data_version`，没有过滤核心实体（航线）
- ❌ 如果创建了其他航线的订单也会通过（不够严格）

**修改后：**
```ruby
add_assertion "创建了机票订单", weight: 20 do
  all_bookings = Booking
    .joins(:flight)
    .where(
      flights: {
        departure_city: @origin,        # ✅ 过滤核心实体：航线
        destination_city: @destination,  # ✅ 过滤核心实体：航线
        data_version: 0
      },
      data_version: @data_version
    )
    .order(created_at: :desc)
    .to_a
  
  expect(all_bookings).not_to be_empty, "未找到任何#{@origin}→#{@destination}的订单记录"
  @booking = all_bookings.first
end
```

**改进点：**
- ✅ 遵循标准：第一条断言必须过滤核心实体（航线）
- ✅ 查询更精确：只查询上海→深圳的订单
- ✅ 错误消息更清晰：明确指出缺少哪条航线的订单

---

#### 问题2：缺少数据规范验证

**标准要求：**
> 必须验证数据来自 demo_user，不是硬编码（防止 AI Agent 硬编码任意名字通过验证）

**新增断言：**
```ruby
# 断言4: 乘客信息正确（验证来自 demo_user，不是硬编码）
add_assertion "乘客信息正确（张三 13800138000）", weight: 10 do
  expect(@booking.passenger_name).to eq('张三'),
    "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
  expect(@booking.contact_phone).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
end
```

**改进点：**
- ✅ 新增数据规范验证断言
- ✅ 确保使用 demo_user 的 passengers 数据（张三 13800138000）
- ✅ 防止 AI Agent 硬编码任意姓名/电话号码

---

### 3. 断言权重调整 ⚖️

**修改前：**
```
断言1: 订单已创建 (20%)
断言2: 航线正确 (10%)
断言3: 日期正确 (10%)
断言4: 最优惠套餐 (30%)
断言5: 支付金额准确 (20%)
断言6: 出行人数正确 (10%)
总计: 100%
```

**修改后：**
```
断言1: 创建了机票订单 (20%)          ← 查询 + 存储
断言2: 航线正确 (10%)                 ← 核心实体验证
断言3: 出行日期正确 (10%)             ← 关键属性
断言4: 乘客信息正确 (10%)             ← 数据规范验证 ⭐ 新增
断言5: 最优惠套餐 (30%)               ← 业务逻辑（最高权重）
断言6: 支付金额准确 (10%)             ← 关键属性（调整：20% → 10%）
断言7: 出行人数正确 (10%)             ← 关键属性
总计: 100%
```

**改进点：**
- ✅ 符合标准的权重分配原则：
  - 订单存在 (20%)
  - 核心实体 (10%)
  - 关键属性 (10% 每个)
  - 业务逻辑 (30% - 最高权重)
- ✅ 新增数据规范验证断言 (10%)
- ✅ 调整支付金额权重 (20% → 10%)，为新断言腾出空间

---

### 4. 代码规范优化 📝

#### 4.1 数据引用标准化

**修改前：**
```ruby
passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
```

**修改后：**
```ruby
passenger = user.passengers.find_by!(name: '张三', data_version: 0)
```

**改进点：**
- ✅ 使用关联查询更符合 Rails 惯例
- ✅ 与标准文档示例一致

---

#### 4.2 prepare 返回值优化

**修改前：**
```ruby
{
  task: "请搜索后天从#{@origin}到#{@destination}的所有航班套餐，找出最终成本最低的并预订（#{@passenger_count}人出行）",
  ...
}
```

**修改后：**
```ruby
{
  task: "给张三订后天去深圳的机票（选最便宜的经济舱）",
  task_detail: "请搜索后天从#{@origin}到#{@destination}的所有航班套餐，找出最终成本最低的并预订（#{@passenger_count}人出行）",
  ...
}
```

**改进点：**
- ✅ `task` 字段使用用户视角的自然语言
- ✅ `task_detail` 字段包含详细的技术描述
- ✅ 更清晰的分层结构

---

#### 4.3 错误消息增强

**修改前：**
```ruby
expect(@booking.flight.departure_city).to eq(@origin)
```

**修改后：**
```ruby
expect(@booking.flight.departure_city).to eq(@origin),
  "出发城市错误。期望: #{@origin}, 实际: #{@booking.flight.departure_city}"
```

**改进点：**
- ✅ 所有断言都包含清晰的错误消息
- ✅ 错误消息格式：`期望值 vs 实际值`
- ✅ 便于调试和问题定位

---

## 📊 测试结果

```bash
rake validator:simulate_single[v010_search_cheapest_flight_validator]
```

### ✅ 测试通过 (100/100)

```
✅ Verify Result:
{
  "execution_id": "20e75d8f-8e12-4904-b3de-3a4b60786aa6",
  "status": "passed",
  "score": 100,
  "assertions": [
    { "name": "创建了机票订单", "weight": 20, "passed": true },
    { "name": "航线正确（上海→深圳）", "weight": 10, "passed": true },
    { "name": "出行日期正确（后天 02月10日）", "weight": 10, "passed": true },
    { "name": "乘客信息正确（张三 13800138000）", "weight": 10, "passed": true },
    { "name": "选择了最优惠的套餐（考虑返现后成本最低）", "weight": 30, "passed": true },
    { "name": "订单支付金额准确（全额支付，返现后续到账）", "weight": 10, "passed": true },
    { "name": "出行人数正确（1人）", "weight": 10, "passed": true }
  ],
  "errors": []
}
```

---

## 📚 遵循的标准原则

### 1. 题目格式 ✅
- ✅ 格式：`给 [受益人] + 动词 + 核心目标 + （关键约束）`
- ✅ 包含受益人（张三）
- ✅ 自然语言表达
- ✅ 避免操作细节

### 2. demo_user 数据使用 ✅
- ✅ 使用 `user.passengers.find_by!` 查询乘客
- ✅ 验证数据来自 demo_user（姓名、电话）
- ✅ 避免硬编码

### 3. verify 断言规则 ✅
- ✅ 第一条断言查询并存储订单
- ✅ 包含 `data_version: @data_version`
- ✅ 过滤核心实体（航线），不过滤待验证属性
- ✅ 权重总和 = 100%
- ✅ 添加数据规范验证

---

## 🎯 关键改进点总结

| 方面 | 改进前 | 改进后 | 影响 |
|------|--------|--------|------|
| **题目** | 搜索...最便宜航班套餐 | 给张三订...机票 | ⭐⭐⭐ 用户体验 |
| **查询逻辑** | 只过滤 data_version | 过滤航线 + data_version | ⭐⭐⭐ 精确度 |
| **数据验证** | 无 | 验证 demo_user 数据 | ⭐⭐⭐ 安全性 |
| **权重分配** | 缺少数据验证断言 | 7个断言均衡分配 | ⭐⭐ 评分合理性 |
| **错误消息** | 部分缺失 | 全部包含详细消息 | ⭐⭐ 调试友好 |

---

## 🏆 最佳实践

1. **题目设计**：始终从用户视角出发，使用"给XX"/"帮XX"开头
2. **查询过滤**：第一条断言必须过滤核心实体，不过滤待验证属性
3. **数据验证**：必须验证关键数据来自 demo_user（姓名、电话、地址等）
4. **权重分配**：业务逻辑最高（30%），其他断言均衡分配
5. **错误消息**：每个断言都要有清晰的错误消息（期望 vs 实际）

---

## 📝 检查清单

- [x] 题目格式：包含受益人和关键约束
- [x] 数据引用：使用 `user.passengers.find_by!`
- [x] 第一条断言：查询 + 过滤核心实体 + 存储
- [x] 数据规范验证：验证乘客信息来自 demo_user
- [x] 权重总和：100%
- [x] 错误消息：所有断言都有清晰的错误描述
- [x] 测试通过：`rake validator:simulate_single` 100分

---

## 🔗 参考文档

- `docs/VALIDATOR_WRITING_STANDARDS.md` - 验证器编写标准
- `app/validators/support/data_packs/v1/demo_user.rb` - Demo 用户数据
