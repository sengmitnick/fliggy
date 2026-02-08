# Validator 编写标准

## 一、题目格式（用户视角）

**格式：** `给/帮 [受益人] + 动词 + 核心目标 + （关键约束）`

**✅ 正确示例：**
- `帮张三订去中国香港的随身WiFi（租1台用5天，选最便宜的，北京朝阳区自取）`
- `给张三预订后天入住一晚深圳的经济型酒店（预算≤500元，选性价比最高的）`
- `给张三和李四订明天去上海的机票（选最便宜的经济舱）`

**❌ 错误示例：**
- `预订后天入住一晚深圳的经济型酒店（1间房，1成人，入住人填张三）` ← 像表单字段
- `订WiFi邮寄到北京朝阳区建国路118号，联系人张三13800138000` ← 像操作手册

**应该包含：** 受益人、核心目标、关键约束（预算/最便宜/时间要求）  
**不应包含：** 具体地址、电话号码、操作步骤、表单字段细节

---

## 二、demo_user 数据使用

**数据文件：** `app/validators/support/data_packs/v1/demo_user.rb`

**demo@travel01.com 提供：**
- **passengers**（出行人）: 张三、李四、王芳、刘强、小明、小红
- **contacts**（联系人）: 张三、王五、赵六  
- **addresses**（收货地址）: 张三（北京朝阳）、李四（上海浦东）

**查看详细信息：** 查看上述文件了解完整的姓名、电话、身份证号、地址等信息。

**使用规则：**

| 场景 | 使用数据 | 题目写法 | simulate 代码 | verify 校验 |
|------|---------|---------|--------------|------------|
| 酒店入住人 | passengers | "给张三预订酒店" | `user.passengers.find_by!(name: '张三', data_version: 0)` | guest_name, guest_phone |
| 机票/火车票 | passengers | "给张三订机票" | `user.passengers.find_by!(name: '张三', data_version: 0)` | passenger_id |
| 景点门票 | User + contacts | "帮张三预订门票" | user + `user.contacts.find_by!(name: '张三', data_version: 0)` | user_id + contact_phone |
| 景点活动 | User + contacts | "帮张三预订活动" | user + `user.contacts.find_by!(name: '张三', data_version: 0)` | user_id + contact_phone |
| WiFi联系人 | contacts | "帮张三订WiFi" | `user.contacts.find_by!(name: '张三', data_version: 0)` | contact_name, contact_phone |
| 电话卡邮寄 | addresses | "邮寄到张三的地址" | `user.addresses.find_by!(is_default: true, data_version: 0)` | address 字段 |
| 深度旅游向导 | passengers + contacts | "给张三预订深度旅游" | passenger + contact 分别查询 | traveler_* + contact_* |
| 跟团游（单人） | passengers + contacts | "给张三预订跟团游" | passenger + contact 分别查询 | contact_* + booking_travelers |
| 跟团游（多人/儿童） | passengers + contacts | "给张三和小明预订跟团游" | 每个出行人单独查询 | contact_* + 多条 booking_travelers |

**为什么酒店用 passengers 不用 contacts？**  
→ 入住人需要身份证号（实名制），passengers 表有 `id_number` 字段

**为什么景点门票/活动用 User + contacts？**  
→ user_id：订单所属用户（张三）  
→ contact_phone：联系电话，应从 user.contacts 表获取（13800138000）

**深度旅游向导为什么需要两个信息？**  
→ 游客信息（traveler_*）需要身份证，联系人（contact_*）用于沟通

**跟团游为什么需要联系人和出行人？**  
→ 联系人（contact_name/contact_phone）：用于旅行社沟通，可能不是出行人  
→ 出行人（booking_travelers）：实际参团游客，需要身份证号（订机票/酒店）  
→ 多人/儿童场景：**必须在标题和描述中明确列出所有出行人姓名**（如："给张三和小明预订..."）

**❌ 禁止：**
- 硬编码姓名、电话、地址
- 在 simulate 中创建新用户：`User.find_or_create_by!(...)`

---

## 三、verify 断言规则

### 3.1 查询过滤原则

**第一条断言必须查询并存储订单：**
```ruby
add_assertion "创建了订单", weight: 20 do
  @orders = ModelName
    .where(data_version: @data_version)  # ✅ 必须：会话隔离
    .where(core_entity: @value)          # ✅ 核心实体（酒店名/景点名）
    # ❌ 不要过滤待验证属性（日期/价格/房型）
    .order(created_at: :desc)
    .to_a
  
  expect(@orders).not_to be_empty
  @order = @orders.first
end

return if @order.nil?  # Guard clause
```

**✅ 必须包含：** `data_version: @data_version`、核心业务实体  
**❌ 不能包含：** 待验证的属性（日期、价格、房型）

**为什么？** 如果查询包含 `visit_date: @expected_date`，日期错误时报"未找到订单"而不是"日期错误"，失去评分粒度。

### 3.2 断言权重分配

- **订单存在** (20-25%): 查询订单 + 存储到实例变量
- **核心实体** (10-15%): 酒店名/景点名/航班号正确
- **关键属性** (10-15% 每个): 日期、价格、数量、入住人信息
- **业务逻辑** (20-30%): 最便宜、性价比最高、优化选择

**总和必须 = 100%**

### 3.3 数据规范验证

**必须验证数据来自 demo_user，不是硬编码：**

**示例 1：酒店入住人信息**
```ruby
add_assertion "入住人信息正确（张三 13800138000）", weight: 10 do
  expect(@order.guest_name).to eq('张三'),
    "入住人姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.guest_name}"
  expect(@order.guest_phone).to eq('13800138000')
end
```

**示例 2：景点门票/活动订单**
```ruby
add_assertion "订单属于张三", weight: 15 do
  expected_user = User.find_by(email: 'demo@travel01.com', data_version: 0)
  expected_contact = expected_user.contacts.find_by(name: '张三', data_version: 0)
  
  expect(@order.user_id).to eq(expected_user.id),
    "订单用户错误。期望: 张三（#{expected_user.email}）, 实际: #{@order.user&.email}"
  expect(@order.contact_phone).to eq(expected_contact.phone),
    "联系电话错误。期望: #{expected_contact.phone}（demo_user数据）, 实际: #{@order.contact_phone}"
end
```

**为什么需要这条断言？**  
→ 防止 AI Agent 硬编码任意名字通过验证  
→ 确保订单关联到正确的用户账号

---

## 四、业务规则速查

| 业务 | 交付方式 | 字段 | 数据来源 | 备注 |
|------|---------|------|---------|------|
| WiFi租赁 | **只能自取** | delivery_method: 'pickup' | PickupLocation 表 | - |
| 电话卡 | **只能邮寄** | delivery_method: 'mail' | user.addresses | - |
| 酒店 | N/A | guest_name, guest_phone | user.passengers | 需实名 |
| 机票/火车 | N/A | passenger_id | user.passengers | 需实名 |
| 深度旅游向导 | N/A | traveler_* + contact_* | passengers + contacts | 游客需实名 + 联系人 |
| 跟团游 | N/A | contact_* + booking_travelers | passengers + contacts | 联系人 + 出行人（多人需明确姓名） |

---

## 五、检查清单

### 题目检查
- [ ] 格式："给XX预订..." 或 "帮XX订..."
- [ ] 包含受益人和关键约束
- [ ] 删除具体地址、电话、操作步骤

### 数据引用检查
- [ ] 酒店入住人使用 passengers（不是 contacts）
- [ ] WiFi联系人使用 contacts
- [ ] 邮寄地址使用 addresses
- [ ] 删除 `User.find_or_create_by!` 创建用户

### 验证断言检查
- [ ] 第一条断言查询订单 + 包含 `data_version: @data_version`
- [ ] 查询只过滤核心实体，不过滤待验证属性
- [ ] 添加数据规范验证（入住人/联系人来自 demo_user）
- [ ] 权重总和 = 100%

---

**核心原则：**
- 题目 = 用户说话方式（自然语言）
- prepare = Agent 任务参数（结构化数据）
- simulate = 真实操作模拟（使用 demo_user 数据）
- verify = 精确评分断言（分离查询和验证逻辑）
