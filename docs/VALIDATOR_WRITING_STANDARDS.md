# Validator 编写标准

## 一、题目描述标准

### 1.1 用户视角原则

**❌ 错误示例（像操作手册）：**
```
预订境外随身WiFi（中国香港1台5天，邮寄到北京朝阳区建国路118号，联系人张三13800138000，7天后取件，选最便宜13元/天）
```

**✅ 正确示例（自然语言）：**
```
帮张三订去中国香港的随身WiFi（租1台用5天，选最便宜的，北京朝阳区自取）
```

### 1.2 信息粒度控制

**应该包含的信息：**
- ✅ 业务目标：订WiFi、订机票、订酒店
- ✅ 核心参数：去哪里、几天、几个人
- ✅ 关键约束：最便宜、最快、特定时间
- ✅ 受益人：帮张三、给李四

**不应该包含的信息：**
- ❌ 具体地址：北京市朝阳区建国路118号
- ❌ 电话号码：13800138000
- ❌ 价格细节：13元/天
- ❌ 操作步骤：搜索 → 对比 → 选择 → 填写

### 1.3 关联数据引用方式

**❌ 错误：硬编码数据**
```ruby
# 题目中写明
"联系人: 张三 13800138000"
"邮寄到: 北京市朝阳区建国路118号"

# simulate 中硬编码
contact_info: { name: "张三", phone: "13800138000" }
delivery_info: { address: "北京市朝阳区建国路118号" }
```

**✅ 正确：引用 demo_user 数据**
```ruby
# 题目中只提人名
"联系人填张三"
"邮寄到张三的地址"  # 或 "北京朝阳区自取"

# prepare 中查询
@contact_name = "张三"
@pickup_location = PickupLocation.find_by!(city: '北京', district: '朝阳区', data_version: 0)

# simulate 中从 demo_user 获取
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
contact = user.contacts.find_by!(name: '张三', data_version: 0)
pickup_location = PickupLocation.find_by!(city: '北京', district: '朝阳区', data_version: 0)

# 使用实际数据
contact_info: { name: contact.name, phone: contact.phone }
rental_info: { pickup_location: pickup_location.full_info }
```

---

## 二、demo_user 数据使用规范

### 2.1 可用数据类型

demo_user (demo@travel01.com) 提供以下数据：

#### 乘机人 (passengers)
- 张三 (成人，身份证110101199001011234，电话13800138000，is_self: true)
- 李四 (成人，身份证110101199002022345，电话13900139000)
- 王芳 (成人)
- 刘强 (成人)
- 小明 (儿童，9岁)
- 小红 (儿童，6岁)

#### 联系人 (contacts)
- 张三 (电话13800138000，邮箱zhangsan@example.com，is_default: true)
- 王五 (电话13700137000)
- 赵六 (电话13600136000)

#### 收货地址 (addresses)
- 张三 (北京市朝阳区建国路88号SOHO现代城，is_default: true)
- 李四 (上海市浦东新区陆家嘴环路1000号)

### 2.2 使用规则

**题目涉及以下场景时，必须使用 demo_user 数据：**

| 场景 | 使用数据 | 题目写法 | 验证方式 |
|------|---------|---------|---------|
| 出行人 | passengers | "带小明、小红去..." | 验证 passenger_id |
| 联系人 | contacts | "联系人填张三" | 验证联系人姓名（电话可选） |
| 收货地址 | addresses | "邮寄到张三的地址" | 验证地址完整匹配 |
| 自取地点 | PickupLocation | "北京朝阳区自取" | 验证自取地点城市+区域 |

**❌ 禁止行为：**
- 在 simulate 中创建新的 User、Contact、Address
- 使用 `User.find_or_create_by!(email: 'test@example.com')`
- 硬编码联系人信息、地址信息

---

## 三、前端功能对齐

### 3.1 WiFi 租赁业务规则

**CRITICAL：WiFi 只支持自取，不支持邮寄**

```ruby
# ❌ 错误
delivery_method: 'mail'
delivery_info: { address: "...", method: "mail" }

# ✅ 正确
delivery_method: 'pickup'
rental_info: { 
  pickup_location: "北京朝阳区建国路88号SOHO现代城"  # 使用 PickupLocation
}
```

**自取地点选择逻辑：**
1. 前端通过 `params[:pickup_location_id]` 传递自取地点ID
2. 从 PickupLocation 表查询具体地点信息
3. 将 `pickup_location.full_info` 存储到 `rental_info` 中

### 3.2 电话卡业务规则

**电话卡只支持邮寄，不支持自取**

```ruby
delivery_method: 'mail'
delivery_info: { 
  address_id: address.id,
  full_address: address.full_address 
}
```

### 3.3 地址/联系人选择逻辑

**前端通过选择框选择，不是手动输入：**

```ruby
# 地址选择（电话卡邮寄）
params[:address_id] → user.addresses.find(id)
delivery_info: { address_id: ..., full_address: ... }

# 联系人选择（WiFi自取）
params[:passenger_id] → user.passengers.find(id)
contact_info: { passenger_id: ..., name: ..., phone: ... }
```

---

## 四、验证断言标准

### 4.1 断言结构

**第一条断言必须建立数据基线：**

```ruby
def verify
  # 断言1: 必须查询订单并存储（20-25%权重）
  add_assertion "创建了订单", weight: 20 do
    @orders = ModelName
      .joins(:associations)
      .where(associations: { core_entity: @entity_value })  # 核心实体过滤
      .where(data_version: @data_version)                    # 会话隔离（必须）
      .order(created_at: :desc)
      .to_a
    
    expect(@orders).not_to be_empty, "未找到任何记录"
    @order = @orders.first
  end
  
  return if @order.nil?  # Guard clause
  
  # 断言2-N: 验证具体属性（10-15%权重）
end
```

### 4.2 查询过滤规则

**✅ MUST 包含的过滤条件：**
- `data_version: @data_version` （会话隔离，必须）
- 核心业务实体（景点名、酒店名、航班号）

**❌ NEVER 包含的过滤条件：**
- 待验证的属性（visit_date、room_type、seat_class）

**原因：** 如果查询中包含 `visit_date: @expected_date`，当日期错误时报错会是"未找到订单"而不是"游玩日期错误"，失去评分粒度。

### 4.3 地址/联系人验证

**WiFi 自取地点验证：**
```ruby
add_assertion "取件地点正确（北京朝阳区）", weight: 5 do
  rental_info = @order.rental_info.is_a?(String) ? JSON.parse(@order.rental_info) : @order.rental_info
  pickup_location = rental_info['pickup_location']
  
  expect(pickup_location).to include('北京'), "取件地点应在北京"
  expect(pickup_location).to include('朝阳区'), "取件地点应在朝阳区"
end
```

**电话卡邮寄地址验证（如果业务需要验证具体地址）：**
```ruby
add_assertion "收货地址正确（张三的地址）", weight: 5 do
  delivery_info = @order.delivery_info
  actual_address = delivery_info['full_address']
  
  expect(actual_address).to eq(@expected_full_address),
    "地址错误。期望: #{@expected_full_address}（张三的地址），实际: #{actual_address}"
end
```

**联系人验证：**
```ruby
add_assertion "联系人信息正确（张三）", weight: 5 do
  contact_info = @order.contact_info
  expect(contact_info['name']).to eq('张三'), "联系人姓名错误"
  expect(contact_info['phone']).not_to be_nil, "联系人电话为空"
  # 不验证具体电话号码，因为可能从 passengers 或 contacts 获取
end
```

---

## 五、完整示例对比

### 5.1 修改前（v052）

**题目：**
```
预订境外随身WiFi（中国香港1台5天，邮寄到北京朝阳区建国路118号，联系人张三13800138000，7天后取件，选最便宜13元/天）
```

**问题：**
1. ❌ 题目像操作手册，列出所有细节
2. ❌ 硬编码地址和电话
3. ❌ WiFi 使用邮寄方式（前端不支持）
4. ❌ simulate 中创建新用户

### 5.2 修改后（v052）

**题目：**
```
帮张三订去中国香港的随身WiFi（租1台用5天，选最便宜的，北京朝阳区自取）
```

**prepare：**
```ruby
def prepare
  @rental_days = 5
  @quantity = 1
  @delivery_method = "pickup"
  @contact_name = "张三"
  
  # 查找自取地点
  @pickup_location = PickupLocation.find_by!(
    city: '北京',
    district: '朝阳区',
    data_version: 0
  )
  
  { task: "帮张三订去中国香港的随身WiFi，租1台用5天，选最便宜的" }
end
```

**simulate：**
```ruby
def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  contact = user.contacts.find_by!(name: '张三', data_version: 0)
  pickup_location = PickupLocation.find_by!(city: '北京', district: '朝阳区', data_version: 0)
  
  InternetOrder.create!(
    user: user,
    delivery_method: 'pickup',
    rental_info: {
      rental_days: @rental_days,
      pickup_location: pickup_location.full_info
    },
    contact_info: {
      name: contact.name,
      phone: contact.phone
    },
    data_version: @data_version
  )
end
```

**verify：**
```ruby
def verify
  add_assertion "取件地点正确（北京朝阳区）", weight: 5 do
    rental_info = @order.rental_info.is_a?(String) ? JSON.parse(@order.rental_info) : @order.rental_info
    pickup_location = rental_info['pickup_location']
    
    expect(pickup_location).to include('北京')
    expect(pickup_location).to include('朝阳区')
  end
  
  add_assertion "取件方式正确（自取）", weight: 5 do
    expect(@order.delivery_method).to eq('pickup')
  end
end
```

---

## 六、修改检查清单

在调整每个 validator 前，按以下清单检查：

### 题目检查
- [ ] 题目是否像用户自然说话？
- [ ] 是否移除了具体地址、电话号码？
- [ ] 是否移除了操作步骤描述？
- [ ] 是否移除了价格细节？

### 数据引用检查
- [ ] 涉及联系人的，是否从 demo_user.contacts 获取？
- [ ] 涉及乘机人的，是否从 demo_user.passengers 获取？
- [ ] 涉及收货地址的，是否从 demo_user.addresses 获取？
- [ ] simulate 中是否删除了 `User.find_or_create_by!` 创建测试用户？

### 业务规则检查
- [ ] WiFi 是否使用 pickup 方式（不是 mail）？
- [ ] 电话卡是否使用 mail 方式（不是 pickup）？
- [ ] 自取是否使用 PickupLocation？
- [ ] 邮寄是否使用 user.addresses？

### 验证断言检查
- [ ] 第一条断言是否查询订单并存储到 @order？
- [ ] 是否包含 `data_version: @data_version` 过滤？
- [ ] 查询是否只过滤核心实体，不过滤待验证属性？
- [ ] 地址/联系人验证是否合理（不过度验证具体电话）？

---

## 七、常见错误汇总

| 错误类型 | 错误示例 | 正确示例 |
|---------|---------|---------|
| 题目过于详细 | "邮寄到北京市朝阳区建国路118号" | "邮寄到张三的地址" 或 "北京朝阳区自取" |
| 硬编码联系人 | `contact_info: { name: "张三", phone: "13800138000" }` | `contact = user.contacts.find_by!(name: '张三')` |
| WiFi使用邮寄 | `delivery_method: 'mail'` | `delivery_method: 'pickup'` |
| 创建测试用户 | `User.find_or_create_by!(email: 'test@...')` | `User.find_by!(email: 'demo@travel01.com')` |
| 查询包含验证属性 | `.where(visit_date: @date, data_version: @v)` | `.where(data_version: @v)` + 单独验证 date |
| 缺少 data_version | `.where(name: '...')` | `.where(name: '...', data_version: 0)` |

---

**最后提醒：**
- 题目写给用户看 → 自然语言
- prepare 写给 Agent 看 → 任务参数
- verify 写给评分系统看 → 精确断言
- simulate 写给测试用的 → 模拟真实操作

每个部分有不同的受众和目的，不要混淆。
