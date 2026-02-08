# Validator 编写标准

## 一、题目格式（用户视角）

**格式：** `给/帮 [受益人] + 动词 + 核心目标 + （关键约束）`

**✅ 正确示例：**
- `给张三预订韩国5G高速WiFi（租1台用5天）`
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
- **passengers**（出行人）: 张三、李四、王芳、刘强、小明、小红、陈静
- **contacts**（联系人）: 张三、王五、赵六  
- **addresses**（收货地址）: 张三（北京朝阳）、李四（上海浦东）

**家庭关系：**
- **家庭1**: 张三（夫）+ 王芳（妻）+ 小明（子）  
- **家庭2**: 刘强（夫）+ 陈静（妻）+ 小红（女）  
- **其他**: 李四（张三的弟弟）

**使用规则：**

| 场景 | 使用数据 | verify 字段 | 数据格式 |
|------|---------|------------|----------|
| 酒店入住人 | passengers | guest_name, guest_phone | 字符串 |
| 机票/火车票 | passengers | passenger_id | ID |
| **接送机服务** | **passengers** | **passenger_name, passenger_phone** | **字符串** |
| **景点门票/活动** | **passengers** | **contact_phone + passenger_ids** | **字符串 + ID数组** |
| **保险被保人** | **passengers** | **insured_persons** | **`[{name, id_number}]`** |
| **流量包充值** | **passengers** | **contact_info: {phone}** | **JSON字符串** |
| **WiFi租赁邮寄** | **addresses** | **contact_info: {name, phone, address}** | **JSON字符串 + delivery_method: 'mail'** |
| **SIM卡/电话卡邮寄** | **addresses** | **contact_info: {name, phone, address}** | **JSON字符串 + delivery_method: 'mail'** |
| 深度旅游/跟团游 | passengers + contacts | traveler_*/contact_* + booking_travelers | 混合 |

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

### 3.3 乘客/联系人信息验证

**核心原则：** prepare 查询 `data_version: 0` → simulate 使用实例变量 → verify 验证

#### 单人场景（基础模式）

```ruby
# prepare: 查询基础数据
@passenger = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .passengers.find_by!(name: '张三', data_version: 0)
@expected_phone = @passenger.phone

# simulate: 使用实例变量
ModelName.create!(
  passenger_name: @passenger.name,
  passenger_phone: @expected_phone,
  data_version: @data_version
)

# verify: 验证匹配（10分）
add_assertion "乘客信息正确", weight: 10 do
  expect(@order.passenger_phone).to eq(@expected_phone)
end
```

#### 多人场景（家庭/朋友/亲子/独立儿童/大团体）

**标题格式：**
- 2-3人：列全名 → `给张三、李四、王芳预订长城门票（3人，最便宜）`
- 4人以上：简化 → `给张三一家和朋友预订度假村门票（6人，最优惠）`

**代码模式：**
```ruby
# prepare: 查询所有出行人
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
@zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
@lisi = user.passengers.find_by!(name: '李四', data_version: 0)
@wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)

@expected_contact_phone = @zhangsan.phone  # 联系人
@expected_passenger_names = [@zhangsan.name, @lisi.name, @wangfang.name]

# simulate: 使用 passenger_ids 关联游客
TicketOrder.create!(
  ticket_id: adult_ticket.id,
  contact_phone: @expected_contact_phone,
  passenger_ids: [@zhangsan.id, @lisi.id, @wangfang.id],
  quantity: 3,
  data_version: @data_version
)

# verify: 联系人（10分）+ 游客信息（10分）= 合计20分
add_assertion "联系人信息正确（#{@expected_contact_phone}）", weight: 10 do
  @orders.each { |o| expect(o.contact_phone).to eq(@expected_contact_phone) }
end

add_assertion "游客信息正确（张三、李四、王芳）", weight: 10 do
  all_ids = @orders.flat_map { |o| o.passenger_ids || [] }.compact.uniq
  actual_names = Passenger.where(id: all_ids, data_version: 0).pluck(:name).sort
  expect(actual_names).to match_array(@expected_passenger_names.sort),
    "游客名单错误。期望: #{@expected_passenger_names.sort.join('、')}，实际: #{actual_names.join('、')}"
end
```

**场景差异：**
- **家庭出游**（父母+孩子）：成人票订单 + 儿童票订单，联系人通常是父亲
- **朋友结伴**（3-5成人）：单个成人票订单，quantity=人数
- **亲子游**（妈妈+孩子）：成人票1张 + 儿童票1张，联系人是母亲
- **独立儿童**：仅儿童票，联系人是孩子本人
- **大团体**（5人以上）：根据年龄动态分票种

### 3.4 特殊字段验证

**WiFi租赁/SIM卡/电话卡收货地址（20-25分）：**
```ruby
# prepare: 查询收货地址
# WiFi租赁：按受益人姓名查询（给张三订WiFi → 查张三地址）
@address = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .addresses.find_by!(name: '张三', data_version: 0)

# SIM卡/电话卡：查询默认地址（is_default: true）
@address = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .addresses.find_by!(is_default: true, data_version: 0)

@expected_name = @address.name
@expected_phone = @address.phone
@expected_address_keyword = '北京'  # 用于验证

# simulate: 使用真实地址
full_address = "#{@address.province}#{@address.city}#{@address.district}#{@address.detail}"
InternetOrder.create!(
  delivery_method: 'mail',
  contact_info: { name: @expected_name, phone: @expected_phone, address: full_address }.to_json,
  data_version: @data_version
)

# verify: 验证邮寄方式和收货地址
add_assertion "收货地址正确（#{@expected_name}的#{@expected_address_keyword}地址）", weight: 20 do
  expect(@order.delivery_method).to eq('mail'),
    "交付方式错误。期望: mail（邮寄），实际: #{@order.delivery_method}"
  
  contact_info = JSON.parse(@order.contact_info)
  expect(contact_info['name']).to eq(@expected_name)
  expect(contact_info['phone']).to eq(@expected_phone)
  expect(contact_info['address']).to include(@expected_address_keyword),
    "收货地址错误。期望包含: #{@expected_address_keyword}"
end
```

**保险被保人（JSON数组）：**
```ruby
add_assertion "被保人信息正确（姓名+身份证号）", weight: 5 do
  insured = @order.insured_persons.find { |p| p['name'] == '张三' }
  expect(insured).not_to be_nil
  expect(insured['id_number']).not_to be_empty
end
```

**流量包手机号（JSON对象）：**
```ruby
add_assertion "手机号正确", weight: 15 do
  phone = JSON.parse(@order.contact_info)['phone']
  expect(phone).to eq(@expected_phone)
end
```

---

## 四、检查清单

### 题目检查
- [ ] 格式："给XX预订..." 或 "帮XX订..."
- [ ] 包含受益人和关键约束
- [ ] 删除具体地址、电话、操作步骤

### 数据引用检查
- [ ] 乘客信息在 prepare 中预查询（避免 simulate 中使用 data_version: 0）
- [ ] 需身份证号的用 passengers（酒店/机票/保险/接送机）
- [ ] **需收货地址的用 addresses：WiFi租赁（按受益人姓名查询）、SIM卡/电话卡（is_default: true）**
- [ ] 删除 `User.find_or_create_by!` 创建用户
- [ ] simulate 中无 `data_version: 0` 的查询或创建

### 验证断言检查
- [ ] 第一条断言查询订单 + 包含 `data_version: @data_version`
- [ ] 查询只过滤核心实体，不过滤待验证属性
- [ ] 单人场景：乘客信息验证（姓名+电话，10分）
- [ ] **多人场景：联系人断言（10分）+ 游客信息断言（10分）= 合计20分**
- [ ] **收货地址验证：邮寄方式 + 姓名 + 电话 + 地址省市（20-25分）**
- [ ] 添加数据规范验证（乘客/联系人/地址来自 demo_user）
- [ ] 权重总和 = 100%

---

**核心原则：**
- 题目 = 用户说话方式（自然语言）
- prepare = Agent 任务参数（结构化数据）
- simulate = 真实操作模拟（使用 demo_user 数据）
- verify = 精确评分断言（分离查询和验证逻辑）
