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

## 二、日期/时间处理

### 2.1 周末日期描述原则

**❌ 禁止使用"本周末"** - 周六/周日有歧义
**✅ 使用"下周六"或"这周六"** - 明确无歧义

### 2.2 下周六日期计算

```ruby
# 标题和描述统一使用"下周六"
self.title = '给张三等4人预订下周六广州长隆野生动物世界成人票（最便宜）'
self.description = '帮张三、李四、王芳、刘强这4个人订下周六的长隆门票，要最便宜的那家'

# prepare：计算下周六日期
today = Date.current

if today.saturday?
  @visit_date = today + 7.days  # 今天是周六，选择下一个周六
else
  days_until_next_saturday = (6 - today.wday) % 7
  days_until_next_saturday = 7 if days_until_next_saturday == 0  # 今天是周日
  @visit_date = today + days_until_next_saturday.days
end
```

### 2.3 数据包日期范围

**所有与日期相关的数据包必须覆盖 14 天以上：**

```ruby
start_date = Date.today - 1.day  # 支持西时区用户
end_date = start_date + 14.days  # 至少 14 天
```

---

## 三、demo_user 数据使用

**数据文件：** `app/validators/support/data_packs/v1/demo_user.rb`

**demo@travel01.com 提供：**
- **passengers**（出行人）: 张三、李四、王芳、刘强、小明、小红、陈静
- **addresses**（收货地址）: 张三（北京朝阳）、李四（上海浦东）

**使用规则：**

| 场景 | 使用数据 | verify 字段 | delivery_method |
|------|---------|------------|----------------|
| 酒店入住人/机票/火车票 | passengers | guest_name/passenger_id | - |
| **景点门票/活动** | **passengers** | **contact_phone + passenger_ids** | - |
| **WiFi/SIM卡邮寄** | **addresses** | **contact_info: {name, phone, address}** | **'mail'（只支持邮寄）** |
| **签证申请** | **passengers + addresses** | **contact_name, contact_phone, delivery_address** | **'mail'（只支持邮寄）** |

**⚠️ 业务规则约束：**

**WiFi/SIM卡/签证申请：只支持邮寄方式（delivery_method: 'mail'）**
- ❌ 禁止：`home_pickup: true`（上门取件/自取）
- ✅ 必须：`delivery_method: 'mail'`
- 原因：前端只支持邮寄配送，不支持上门取件功能

**❌ 禁止：**
- 硬编码姓名、电话、地址
- 在 simulate 中创建新用户：`User.find_or_create_by!(...)`
- 在签证/WiFi/SIM卡业务中使用 `home_pickup: true` 或 `delivery_method: 'pickup'`

---

## 四、verify 断言规则

### 4.1 查询过滤原则

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

### 4.2 断言权重分配

- **订单存在** (20-25%): 查询订单 + 存储到实例变量
- **核心实体** (10-15%): 酒店名/景点名/航班号正确
- **关键属性** (10-15% 每个): 日期、价格、数量、入住人信息
- **业务逻辑** (20-30%): 最便宜、性价比最高、优化选择

**总和必须 = 100%**

### 4.3 乘客/联系人信息验证

**核心原则：** prepare 查询 `data_version: 0` → simulate 使用实例变量 → verify 验证

#### 单人场景

```ruby
# prepare
@passenger = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .passengers.find_by!(name: '张三', data_version: 0)
@expected_phone = @passenger.phone

# simulate
ModelName.create!(
  passenger_name: @passenger.name,
  passenger_phone: @expected_phone,
  data_version: @data_version
)

# verify（10分）
add_assertion "乘客信息正确", weight: 10 do
  expect(@order.passenger_phone).to eq(@expected_phone)
end
```

#### 多人场景（门票/活动）

**标题格式：**
- 2-3人：列全名 → `给张三、李四、王芳预订长城门票（3人，最便宜）`
- 4人以上：简化 → `给张三等4人预订下周六广州长隆野生动物世界成人票（最便宜）`

**代码模式：**
```ruby
# prepare
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
@zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
@lisi = user.passengers.find_by!(name: '李四', data_version: 0)
@wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
@expected_contact_phone = @zhangsan.phone
@expected_passenger_names = [@zhangsan.name, @lisi.name, @wangfang.name]

# simulate
TicketOrder.create!(
  contact_phone: @expected_contact_phone,
  passenger_ids: [@zhangsan.id, @lisi.id, @wangfang.id],
  quantity: 3,
  data_version: @data_version
)

# verify：联系人（10分）+ 游客信息（10分）= 合计20分
add_assertion "联系人信息正确", weight: 10 do
  @orders.each { |o| expect(o.contact_phone).to eq(@expected_contact_phone) }
end

add_assertion "游客信息正确", weight: 10 do
  all_ids = @orders.flat_map { |o| o.passenger_ids || [] }.compact.uniq
  actual_names = Passenger.where(id: all_ids, data_version: 0).pluck(:name).sort
  expect(actual_names).to match_array(@expected_passenger_names.sort)
end
```

#### 多人签证申请

**业务特点：**
- 多人共用一个订单，只需填写一个联系人和收货地址
- 可以从申请人中任选一人作为联系人
- 收货地址必须与联系人的地址一致
- **⚠️ 只支持邮寄方式（delivery_method: 'mail'），禁止使用上门取件**

**代码模式（v075 案例）：**
```ruby
# prepare
@country_name = '美国'
@traveler_count = 2

# simulate：随机选择联系人
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
contact_names = ['张三', '李四']
selected_contact_name = contact_names.sample
contact_passenger = user.passengers.find_by!(name: selected_contact_name, data_version: 0)
contact_address = user.addresses.find_by!(name: selected_contact_name, data_version: 0)
full_address = "#{contact_address.province}#{contact_address.city}#{contact_address.district}#{contact_address.detail}"

VisaOrder.create!(
  traveler_count: @traveler_count,
  contact_name: contact_passenger.name,
  contact_phone: contact_passenger.phone,
  delivery_method: 'mail',  # ✅ 必须：只支持邮寄方式
  delivery_address: full_address,
  data_version: @data_version
)

# verify：配送方式（5分）+ 联系人（2分）+ 电话匹配（2分）+ 地址匹配（1分）= 合计10分
add_assertion "使用邮寄方式", weight: 5 do
  expect(@visa_order.delivery_method).to eq('mail'),
    "配送方式错误。期望: mail（邮寄），实际: #{@visa_order.delivery_method}"
end

add_assertion "联系人姓名正确（张三或李四）", weight: 2 do
  valid_names = ['张三', '李四']
  expect(valid_names).to include(@visa_order.contact_name)
end

add_assertion "联系电话与联系人匹配", weight: 2 do
  valid_pairs = { '张三' => '13800138000', '李四' => '13900139000' }
  expected_phone = valid_pairs[@visa_order.contact_name]
  expect(@visa_order.contact_phone).to eq(expected_phone)
end

add_assertion "收货地址与联系人匹配", weight: 1 do
  valid_addresses = {
    '张三' => /北京.*朝阳.*建国路.*SOHO/,
    '李四' => /上海.*浦东.*陆家嘴.*1000/
  }
  expected_pattern = valid_addresses[@visa_order.contact_name]
  expect(@visa_order.delivery_address).to match(expected_pattern)
end
```

**关键点：**
- ✅ **必须验证邮寄方式**：`expect(@order.delivery_method).to eq('mail')`（5分）
- ❌ 不要固定联系人：`expect(@order.contact_name).to eq('张三')`
- ✅ 支持任选：`expect(['张三', '李四']).to include(@order.contact_name)`
- ✅ 动态验证电话和地址：根据联系人姓名匹配对应的电话和地址

**与门票/活动场景的区别：**

| 维度 | 门票/活动 | 签证申请 |
|------|---------|---------|
| 订单结构 | quantity=4 + passenger_ids | traveler_count=2 + 单个联系人 |
| 联系人要求 | 固定一人 | 多人任选其一 |
| 验证字段 | contact_phone + passenger_ids | contact_name + contact_phone + delivery_address |
| 权重分配 | 联系人10分 + 游客10分 | 联系人3分 + 电话3分 + 地址4分 |

### 4.4 特殊字段验证

**WiFi租赁/SIM卡收货地址（20-25分）：**
```ruby
# prepare
# WiFi租赁：按受益人姓名查询（给张三订WiFi → 查张三地址）
@address = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .addresses.find_by!(name: '张三', data_version: 0)

# SIM卡/电话卡：查询默认地址（is_default: true）
@address = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  .addresses.find_by!(is_default: true, data_version: 0)

# simulate
full_address = "#{@address.province}#{@address.city}#{@address.district}#{@address.detail}"
InternetOrder.create!(
  delivery_method: 'mail',
  contact_info: { name: @address.name, phone: @address.phone, address: full_address }.to_json,
  data_version: @data_version
)

# verify
add_assertion "收货地址正确", weight: 20 do
  expect(@order.delivery_method).to eq('mail')
  contact_info = JSON.parse(@order.contact_info)
  expect(contact_info['name']).to eq(@address.name)
  expect(contact_info['phone']).to eq(@address.phone)
  expect(contact_info['address']).to include('北京')
end
```

---

## 五、检查清单

### 题目检查
- [ ] 格式："给XX预订..." 或 "帮XX订..."
- [ ] 包含受益人和关键约束
- [ ] **多人场景：description 必须包含具体人名（如：张三、李四、王芳、刘强）**
- [ ] 删除具体地址、电话、操作步骤

### 数据引用检查
- [ ] 乘客信息在 prepare 中预查询（避免 simulate 中使用 data_version: 0）
- [ ] 需身份证号的用 passengers（酒店/机票/保险）
- [ ] **需收货地址的用 addresses：WiFi租赁（按受益人姓名）、SIM卡（is_default: true）、签证申请（按联系人姓名）**
- [ ] **签证/WiFi/SIM卡业务：必须使用 `delivery_method: 'mail'`（只支持邮寄）**
- [ ] 删除 `User.find_or_create_by!` 创建用户
- [ ] simulate 中无 `data_version: 0` 的查询或创建

### 验证断言检查
- [ ] 第一条断言查询订单 + 包含 `data_version: @data_version`
- [ ] 查询只过滤核心实体，不过滤待验证属性
- [ ] 单人场景：乘客信息验证（10分）
- [ ] **多人门票/活动场景：联系人（10分）+ 游客信息（10分）= 20分**
- [ ] **签证多人场景：配送方式（5分）+ 联系人姓名（2分，支持任选）+ 电话匹配（2分）+ 地址匹配（1分）= 10分**
- [ ] **收货地址验证：邮寄方式 + 姓名 + 电话 + 地址（20-25分）**
- [ ] **签证/WiFi/SIM卡：必须验证 `delivery_method: 'mail'`**
- [ ] 权重总和 = 100%

---

**核心原则：**
- 题目 = 用户说话方式（自然语言）
- prepare = Agent 任务参数（结构化数据）
- simulate = 真实操作模拟（使用 demo_user 数据）
- verify = 精确评分断言（分离查询和验证逻辑）
