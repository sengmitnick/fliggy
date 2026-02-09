# V008 Validator 优化总结

## 优化依据

参考文档：`docs/VALIDATOR_WRITING_STANDARDS.md`

---

## 优化前后对比

### 1. 题目格式优化

**❌ 优化前：**
```
购买日本7天无限量流量SIM卡（数量1张）
```

**问题：**
- 缺少受益人（"给谁"）
- 格式像表单字段描述
- 没有关键约束（邮寄地址）

**✅ 优化后：**
```
给张三购买日本7天无限量流量SIM卡（邮寄到默认地址）
```

**符合标准：**
- ✅ 格式："给 [受益人] + 动词 + 核心目标 + （关键约束）"
- ✅ 包含受益人：张三
- ✅ 核心目标：购买日本7天无限量流量SIM卡
- ✅ 关键约束：邮寄到默认地址

---

### 2. simulate 方法 - 使用 demo_user 数据

**❌ 优化前（硬编码）：**
```ruby
contact_info: { 
  name: '张三', 
  phone: '13800138000', 
  address: '测试地址'  # ❌ 硬编码假地址
}.to_json
```

**✅ 优化后（使用真实数据）：**
```ruby
# 2. 查找张三的默认收货地址（电话卡必须邮寄）
default_address = user.addresses.find_by!(is_default: true, data_version: 0)

# 4. 创建订单（使用 demo_user 的真实地址）
full_address = "#{default_address.province}#{default_address.city}#{default_address.district}#{default_address.detail}"
order = InternetOrder.create!(
  # ...
  contact_info: { 
    name: default_address.name,      # "张三"（来自数据包）
    phone: default_address.phone,    # "13800138000"（来自数据包）
    address: full_address            # "北京市北京朝阳区建国路88号SOHO现代城"
  }.to_json
)
```

**改进点：**
- ✅ 从 `user.addresses` 查询张三的默认地址
- ✅ 使用真实的地址数据（省市区+详细地址）
- ✅ 符合业务规则：电话卡必须邮寄（delivery_method: 'mail'）
- ✅ 防止 AI Agent 硬编码任意地址通过验证

---

### 3. verify 方法 - 添加数据规范验证

**❌ 优化前（缺少验证）：**
```ruby
# 只验证了 6 项（订单存在、类型、地区、有效期、流量、数量）
# 没有验证联系人信息和邮寄地址
```

**✅ 优化后（新增 2 个断言）：**

#### 断言7: 邮寄方式和地址正确
```ruby
add_assertion "邮寄方式和地址正确（mail + 张三北京地址）", weight: 10 do
  expect(@order.delivery_method).to eq('mail'),
    "交付方式错误。期望: mail（邮寄），实际: #{@order.delivery_method}"
  
  contact_info = JSON.parse(@order.contact_info)
  expect(contact_info['name']).to eq('张三'),
    "收货人姓名错误。期望: 张三（demo_user地址）, 实际: #{contact_info['name']}"
  expect(contact_info['address']).to include('北京'),
    "收货地址错误。期望包含: 北京（demo_user默认地址）, 实际: #{contact_info['address']}"
end
```

#### 断言8: 联系人信息正确
```ruby
add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
  contact_info = JSON.parse(@order.contact_info)
  expect(contact_info['name']).to eq('张三'),
    "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{contact_info['name']}"
  expect(contact_info['phone']).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{contact_info['phone']}"
end
```

**改进点：**
- ✅ 验证邮寄方式为 `mail`（符合业务规则）
- ✅ 验证收货人姓名来自 demo_user 数据
- ✅ 验证收货地址包含"北京"（demo_user 默认地址）
- ✅ 验证联系人电话为 `13800138000`（demo_user 数据）
- ✅ 防止 AI Agent 随意填写联系人信息

---

### 4. 权重分配优化

**调整后的权重分配：**

| 断言 | 优化前 | 优化后 | 说明 |
|------|--------|--------|------|
| 订单已创建 | 15% | 20% | 提高基础分（第一条断言） |
| 订单类型正确 | 15% | 10% | 降低简单验证权重 |
| 地区正确 | 15% | 15% | 保持不变（核心实体） |
| 有效期正确 | 15% | 10% | 降低属性验证权重 |
| 流量正确 | 15% | 10% | 降低属性验证权重 |
| 购买数量正确 | 25% | 15% | 降低过高权重 |
| **邮寄方式和地址正确** | - | **10%** | **新增：验证邮寄业务规则** |
| **联系人信息正确** | - | **10%** | **新增：验证 demo_user 数据** |
| **总和** | 100% | 100% | ✅ |

**权重调整理由：**
1. 订单存在（20%）：第一条断言，查询并存储订单，权重应该较高
2. 简单属性验证（10-15%）：类型、有效期、流量等简单匹配
3. 核心实体验证（15%）：地区是核心业务实体
4. 业务逻辑验证（10%×2）：邮寄方式 + 联系人信息，防止数据规范违规

---

## 业务规则总结

根据文档 `VALIDATOR_WRITING_STANDARDS.md`：

| 业务 | 交付方式 | 字段 | 数据来源 |
|------|---------|------|---------|
| **电话卡** | **只能邮寄** | delivery_method: 'mail' | user.addresses |
| WiFi租赁 | 只能自取 | delivery_method: 'pickup' | PickupLocation 表 |
| 酒店 | N/A | guest_name, guest_phone | user.passengers |
| 机票/火车 | N/A | passenger_id | user.passengers |

**V008 验证器遵循规则：**
- ✅ 电话卡使用 `delivery_method: 'mail'`
- ✅ 邮寄地址从 `user.addresses` 获取
- ✅ 使用默认收货地址：`is_default: true`

---

## demo_user 数据使用

根据 `app/validators/support/data_packs/v1/demo_user.rb`：

### 收货地址（Addresses）
```ruby
demo_user.addresses.create!([
  {
    name: '张三',
    phone: '13800138000',
    province: '北京市',
    city: '北京',
    district: '朝阳区',
    detail: '建国路88号SOHO现代城',
    address_type: 'delivery',
    is_default: true,  # ✅ 默认地址
    data_version: 0
  },
  {
    name: '李四',
    phone: '13900139000',
    province: '上海市',
    city: '上海',
    district: '浦东新区',
    detail: '陆家嘴环路1000号',
    address_type: 'delivery',
    data_version: 0
  }
])
```

**V008 使用方式：**
```ruby
default_address = user.addresses.find_by!(is_default: true, data_version: 0)
# 结果：张三的北京地址
```

---

## 测试结果

✅ **所有断言通过（100/100 分）：**

```json
{
  "execution_id": "1d601f61-f93d-4223-b6a1-a7ae82fcbed5",
  "status": "passed",
  "score": 100,
  "assertions": [
    {"name": "创建了境外上网订单", "weight": 20, "passed": true},
    {"name": "订单类型正确（SIM卡）", "weight": 10, "passed": true},
    {"name": "地区正确（日本）", "weight": 15, "passed": true},
    {"name": "有效期正确（7天）", "weight": 10, "passed": true},
    {"name": "流量正确（无限量）", "weight": 10, "passed": true},
    {"name": "购买数量正确（1张）", "weight": 15, "passed": true},
    {"name": "邮寄方式和地址正确（mail + 张三北京地址）", "weight": 10, "passed": true},
    {"name": "联系人信息正确（张三 13800138000）", "weight": 10, "passed": true}
  ]
}
```

**模拟订单信息：**
```json
{
  "action": "create_internet_order",
  "order_id": 383,
  "sim_card_name": "日本7天流量卡·无限量",
  "validity_days": 7,
  "data_limit": "无限量",
  "price": "88.0",
  "delivery_address": "北京市北京朝阳区建国路88号SOHO现代城",  // ✅ 真实地址
  "recipient": "张三",  // ✅ demo_user 数据
  "user_email": "demo@travel01.com"
}
```

---

## 优化清单

根据 `VALIDATOR_WRITING_STANDARDS.md` 检查清单：

### 题目检查
- [x] 格式："给XX预订..." 或 "帮XX订..."
- [x] 包含受益人和关键约束
- [x] 删除具体地址、电话、操作步骤

### 数据引用检查
- [x] 邮寄地址使用 addresses（电话卡业务）
- [x] 使用 `is_default: true` 查找默认地址
- [x] 删除硬编码的"测试地址"

### 验证断言检查
- [x] 第一条断言查询订单 + 包含 `data_version: @data_version`
- [x] 查询只过滤核心实体，不过滤待验证属性
- [x] 添加数据规范验证（邮寄地址和联系人来自 demo_user）
- [x] 权重总和 = 100%

---

## 核心原则

根据文档总结：

1. **题目 = 用户说话方式（自然语言）**
   - ✅ "给张三购买..." 而不是 "购买数量1张"

2. **prepare = Agent 任务参数（结构化数据）**
   - ✅ 包含 recipient, delivery_method 等参数

3. **simulate = 真实操作模拟（使用 demo_user 数据）**
   - ✅ 从 `user.addresses` 查询真实地址
   - ✅ 不硬编码任何联系人信息

4. **verify = 精确评分断言（分离查询和验证逻辑）**
   - ✅ 第一条断言查询订单（只过滤 data_version 和核心实体）
   - ✅ 后续断言分别验证各项属性
   - ✅ 新增数据规范验证（防止硬编码）

---

## 总结

优化后的 V008 验证器：

1. ✅ 题目符合用户视角（"给张三购买..."）
2. ✅ 使用 demo_user 的真实地址数据
3. ✅ 添加邮寄方式和联系人信息验证
4. ✅ 权重分配合理（总和100%）
5. ✅ 符合电话卡业务规则（delivery_method: 'mail'）
6. ✅ 防止 AI Agent 硬编码通过验证

测试结果：**100/100 分通过** ✅
