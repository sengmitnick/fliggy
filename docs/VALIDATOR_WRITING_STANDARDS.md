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

## 四、日期/时间处理最佳实践

### 4.1 日期描述原则

**问题：** 使用“本周末”有歧义

当今天是周六或周日时，“本周末”含义不清：
- 如果今天是周六：“本周末”指今天还是明天？
- 如果今天是周日：“本周末”指今天还是已过去？

**✅ 解决方案：使用明确的星期几**
- 使用 **“下周六”** 而非“本周末”
- 如果需要本周六，使用 **“这周六”**

### 4.2 周末日期计算模式

#### 场景：预订下周六的门票/酒店/活动

**错误做法：**
```ruby
# ✖️ 问题：使用“本周末”描述
self.title = '给张三等4人预订本周末长隆野生动物世界成人票'
self.description = '帮张三等4人订本周末的长隆门票'  # 歧义！

# prepare
today = Date.current
@visit_date = today + (6 - today.wday).days  # 如果今天是周六，wday=6，结果是今天0天！
```

**✅ 正确做法（v071 案例）：**

```ruby
# 标题：使用“下周六”明确表达
self.title = '给张三等4人预订下周六广州长隆野生动物世界成人票（最便宜）'

# 描述：同样使用“下周六”
self.description = '帮张三、李四、王芳、刘强这4个人订下周六的长隆野生动物世界门票，要最便宜的那家'

# prepare：计算下周六日期（处理边界情况）
today = Date.current

if today.saturday?
  # 如果今天是周六，选择下一个周六（7天后）
  @visit_date = today + 7.days
else
  # 其他日子，计算到下一个周六的天数
  days_until_next_saturday = (6 - today.wday) % 7
  days_until_next_saturday = 7 if days_until_next_saturday == 0  # 如果今天是周日，下周六是7天后
  @visit_date = today + days_until_next_saturday.days
end

# task 描述：使用统一的“下周六”（不再需要 @date_description_short 变量）
{
  task: "请为4位成人预订下周六（#{@visit_date.strftime('%Y年%m月%d日')}）长隆野生动物世界的成人票",
  visit_date: @visit_date.to_s,
  date_description: "下周六（#{@visit_date.strftime('%Y年%m月%d日')}）"
}
```

**逻辑解释：**

| 今天 | today.wday | 计算逻辑 | 结果 |
|------|-----------|---------|------|
| 周一 | 1 | (6-1) % 7 = 5 | 5天后（本周六） |
| 周二 | 2 | (6-2) % 7 = 4 | 4天后（本周六） |
| 周三 | 3 | (6-3) % 7 = 3 | 3天后（本周六） |
| 周四 | 4 | (6-4) % 7 = 2 | 2天后（本周六） |
| 周五 | 5 | (6-5) % 7 = 1 | 1天后（明天周六） |
| **周六** | **6** | **特殊处理** | **7天后（下周六）** |
| **周日** | **0** | **(6-0)%7=6 → 修正为7** | **7天后（下周六）** |

**关键边界处理：**
1. **周六当天**：直接 +7 days（不能选今天）
2. **周日当天**：(6-0)%7=6 → 修正为 7（不能选明天的周一）

### 4.3 数据包日期范围要求

**问题：** 如果今天是周一，“下周六”是 12 天后。如果数据包只有 7 天范围，会导致验证器失败。

**✅ 解决方案：数据包必须覆盖 14 天以上**

**所有与日期相关的数据包文件，必须确保：**

```ruby
# app/validators/support/data_packs/v1/trains.rb
# app/validators/support/data_packs/v1/flights.rb
# app/validators/support/data_packs/v1/hotels.rb
# 等所有需要生成未来日期数据的文件

start_date = Date.today - 1.day  # 支持西时区用户
end_date = start_date + 14.days  # 至少 14 天，共 16 天范围

puts "数据范围: #{start_date} 至 #{end_date} (共16天)"

(start_date..end_date).each do |date|
  # 生成该日期的数据（火车票/航班/酒店等）
end
```

**原因：**
- **最远场景**：周一预订“下周六” = 12 天后
- **安全边界**：14 天范围确保所有场景都有数据
- **时区兼容**：`Date.today - 1.day` 起始支持 UTC-12 用户

**检查命令：**
```bash
# 搜索所有有日期范围的数据包
grep -r "end_date.*+.*days" app/validators/support/data_packs/v1/

# 确保所有结果都是 + 14.days 或更多
```

### 4.4 日期描述用语对照表

| 用语 | 适用场景 | 计算逻辑 | 注意事项 |
|------|---------|---------|----------|
| 明天 | 任意日期 | `Date.current + 1.day` | 无歧义 |
| 后天 | 任意日期 | `Date.current + 2.days` | 无歧义 |
| 这周六 | 需要本周六 | `(6 - today.wday).days` | 周六/周日需特殊处理 |
| **下周六** | **下一个周六** | **见上述逻辑** | **推荐！无歧义** |
| ✖️ 本周末 | 禁止使用 | - | 周六/周日有歧义 |
| ✖️ 本周几 | 禁止使用 | - | 周六/周日不适用 |

### 4.5 时间段描述原则

**✅ 正确方式：**
- “晚上8点后出发” → `departure_time > '20:00'`
- “下午航班” → `departure_time.hour.between?(12, 17)`
- “凌晨1点前到达” → `arrival_time < '01:00' AND arrival_date = departure_date + 1`

**✖️ 错误方式：**
- “晚上航班” → 模糊（18:00还是20:00？）
- “半夜” → 歧义（23:00还是00:00？）

---

## 五、demo_user 数据使用

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

## 六、verify 断言规则

### 6.1 查询过滤原则

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

### 6.2 断言权重分配

- **订单存在** (20-25%): 查询订单 + 存储到实例变量
- **核心实体** (10-15%): 酒店名/景点名/航班号正确
- **关键属性** (10-15% 每个): 日期、价格、数量、入住人信息
- **业务逻辑** (20-30%): 最便宜、性价比最高、优化选择

**总和必须 = 100%**

### 6.3 乘客/联系人信息验证

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
- 4人以上：简化 → `给张三等4人预订这周六广州长隆野生动物世界成人票（最便宜）`

**描述格式（⚠️ 必须包含具体人名）：**
- ✅ `帮张三、李四、王芳、刘强这4个人订这周六的长隆野生动物世界门票，要最便宜的那家`
- ❌ `为4位成人预订本周末的长隆野生动物世界门票并选择最便宜供应商` ← 无具体人名

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

**完整示例：v071（4人朋友结伴）**

```ruby
# 标题
self.title = '给张三等4人预订这周六广州长隆野生动物世界成人票（最便宜）'

# 描述（⚠️ 必须包含具体人名）
self.description = '帮张三、李四、王芳、刘强这4个人订这周六的长隆野生动物世界门票，要最便宜的那家'

# prepare: 查询4位乘客 + 计算下一个周六日期
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
@passengers = user.passengers.where(data_version: 0, name: ['张三', '李四', '王芳', '刘强']).to_a
raise "未找到足够的乘客信息" if @passengers.size < 4
@contact_passenger = @passengers.first  # 张三作为联系人

# 计算下一个周六（避免"本周末"歧义）
today = Date.current
if today.saturday?
  @visit_date = today + 7.days  # 如果今天是周六，选下周六
  @date_description_short = "下周六"
elsif today.sunday?
  @visit_date = today + 6.days  # 如果今天是周日，选6天后的周六
  @date_description_short = "这周六"
else
  @visit_date = today + (6 - today.wday).days  # 工作日，选本周六
  @date_description_short = "这周六"
end

# simulate: 创建订单（quantity=4）
TicketOrder.create!(
  ticket_id: cheapest_ticket.id,
  supplier_id: cheapest_supplier.id,
  quantity: 4,
  contact_phone: @contact_passenger.phone,  # 张三的电话
  passenger_ids: @passengers.map(&:id),     # 4人的ID数组
  visit_date: @visit_date,
  data_version: @data_version
)

# verify: 联系人（10分）+ 乘客信息（10分）
add_assertion "联系电话正确（张三的电话）", weight: 10 do
  expect(@ticket_order.contact_phone).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（张三），实际: #{@ticket_order.contact_phone}"
end

add_assertion "乘客信息正确（4位乘客）", weight: 10 do
  expect(@ticket_order.passenger_ids).to be_present, "未填写乘客信息"
  expect(@ticket_order.passenger_ids.size).to eq(4),
    "乘客数量错误。期望: 4位，实际: #{@ticket_order.passenger_ids&.size || 0}位"
  
  passenger_names = Passenger.where(id: @ticket_order.passenger_ids, data_version: 0).pluck(:name)
  expected_names = ['张三', '李四', '王芳', '刘强']
  expect(passenger_names.sort).to eq(expected_names.sort),
    "乘客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
end
```

**关键点：**
1. **title**：简化为"张三等4人"（不列全名）
2. **description**：必须列出4个具体人名（张三、李四、王芳、刘强）
3. **日期计算**：使用"这周六"/"下周六"而非"本周末"（避免周六/周日当天的歧义）
4. **prepare**：使用 `where(name: [...])` 批量查询4人 + 动态计算日期描述
5. **simulate**：`quantity=4` + `passenger_ids` 数组包含4人ID
6. **verify**：联系人断言（10分）+ 乘客信息断言（10分）= 合计20分

### 6.4 特殊字段验证

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
- [ ] **多人场景：description 必须包含具体人名（如：张三、李四、王芳、刘强），不能用"4位成人"等泛指**
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
