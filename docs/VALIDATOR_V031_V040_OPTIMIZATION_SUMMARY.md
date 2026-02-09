# V031-V040 验证器优化总结

## 优化时间
2025年

## 优化依据
根据 `docs/VALIDATOR_WRITING_STANDARDS.md` 文档标准进行优化

## 优化的验证器列表

### 机票验证器
- **v031**: 给张三订明天杭州到深圳经济舱机票

### 租车验证器
- **v032**: 帮张三租明天上海的车（1天）
- **v033**: 帮张三租后天北京SUV（2天）
- **v034**: 帮张三租明天深圳最便宜的车（预算≤100元/天）
- **v035**: 帮张三租后天广州豪华轿车（3天）
- **v036**: 帮张三租明天杭州商务车（2天，5座以上）

### 跟团游验证器 (v037-v040)
- **v037**: 给张三预订3天后上海周边3天2晚跟团游（1成人）
- **v038**: 给张三预订明天北京4天3晚跟团游（2成人）
- **v039**: 给张三预订后天三亚6天5晚性价比跟团游（预算≤4000元/人）
- **v040**: 给张三预订3天后广州4天3晚跟团游（1成人1儿童）

**⚠️ 重要修正（2025-02-06）**：跟团游需要**两种信息**
1. **联系人信息**（contact_name, contact_phone）- 使用 contacts 表
2. **出行人/游客信息**（booking_travelers 表）- 使用 passengers 表

## 优化内容

### 1. 题目格式优化（所有验证器）

**优化前模式：** "预订/租赁 + 具体内容"
**优化后模式：** "给/帮 [受益人] + 动词 + 核心目标 + (关键约束)"

#### 示例对比

| 验证器 | 优化前 | 优化后 |
|--------|--------|--------|
| v031 | 预订明天杭州到深圳经济舱航班 | 给张三订明天杭州到深圳经济舱机票 |
| v032 | 租赁明天上海任意车辆（1天） | 帮张三租明天上海的车（1天） |
| v037 | 预订3天后上海周边3天2晚跟团游（1成人） | 给张三预订3天后上海周边3天2晚跟团游（1成人） |

**改进理由：** 更符合用户自然语言表达习惯，明确受益人

### 2. demo_user 数据使用（所有验证器）

#### v031（机票）- 使用 passengers 表
```ruby
# 优化前 - 硬编码
passenger_name: '张三',
passenger_id_number: '110101199001011234',
contact_phone: '13800138000'

# 优化后 - 使用 demo_user 数据
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
passenger = user.passengers.find_by!(name: '张三', data_version: 0)

passenger_name: passenger.name,
passenger_id_number: passenger.id_number,
contact_phone: passenger.phone
```

**改进理由：** 
- 机票需要实名信息（身份证号），使用 passengers 表
- 符合真实业务场景

#### v032-v036（租车）- 使用 passengers 表
```ruby
# 优化前 - 硬编码
driver_name: '张三',
driver_id_number: '110101199001011234',
contact_phone: '13800138000'

# 优化后 - 使用 demo_user 数据
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
passenger = user.passengers.find_by!(name: '张三', data_version: 0)

driver_name: passenger.name,
driver_id_number: passenger.id_number,
contact_phone: passenger.phone
```

**改进理由：**
- 租车需要驾驶人身份证号（实名制），使用 passengers 表
- 符合文档规范：需要身份证号的业务用 passengers

#### v037-v040（跟团游）- 同时使用 passengers 和 contacts 表

**⚠️ 重要发现**：跟团游业务需要两种信息：
1. **联系人**（紧急联系人）- 存储在 `tour_group_bookings.contact_name/contact_phone`
2. **出行人**（实际游客）- 存储在 `booking_travelers` 表，需要身份证号

```ruby
# 优化前 - 只有联系人，缺少出行人
TourGroupBooking.create!(
  contact_name: '张三',
  contact_phone: '13800138000',
  # ... 没有创建 booking_travelers
)

# 优化后 - 联系人 + 出行人都需要
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
contact = user.contacts.find_by!(name: '张三', data_version: 0)  # 联系人
passenger = user.passengers.find_by!(name: '张三', data_version: 0)  # 出行人

booking = TourGroupBooking.create!(
  contact_name: contact.name,      # ✅ 联系人信息
  contact_phone: contact.phone,
  # ...
)

# ✅ 创建出行人记录（需要身份证号）
BookingTraveler.create!(
  tour_group_booking_id: booking.id,
  traveler_name: passenger.name,
  id_number: passenger.id_number,
  traveler_type: 'adult',
  data_version: @data_version
)
```

**改进理由：**
- 符合真实业务场景：联系人（接电话）+ 出行人（实际旅游，需要实名）
- 跟团游需要身份证号（机票、酒店实名制），必须用 passengers 表
- contacts 表只存联系方式，不存身份证号

### 3. verify 断言优化（所有验证器）

#### a) 查询过滤优化
```ruby
# 优化前 - 缺少 data_version 过滤
@booking = Booking.order(created_at: :desc).first

# 优化后 - 添加 data_version 过滤
all_bookings = Booking
  .where(data_version: @data_version)  # ✅ 会话隔离
  .order(created_at: :desc)
  .to_a

@booking = all_bookings.first
```

**改进理由：** 
- 确保会话隔离，避免查询到其他验证器的数据
- 符合文档要求："第一条断言必须包含 data_version: @data_version"

#### b) 添加数据规范验证断言

**机票验证器 (v031)**
```ruby
add_assertion "乘机人信息正确（张三 13800138000）", weight: 25 do
  expect(@booking.passenger_name).to eq('张三'),
    "乘机人姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
  expect(@booking.contact_phone).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
  expect(@booking.passenger_id_number).to eq('110101199001011234'),
    "身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{@booking.passenger_id_number}"
end
```

**租车验证器 (v032-v036)**
```ruby
add_assertion "驾驶人信息正确（张三 13800138000）", weight: 10 do
  expect(@order.driver_name).to eq('张三'),
    "驾驶人姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.driver_name}"
  expect(@order.contact_phone).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
  expect(@order.driver_id_number).to eq('110101199001011234'),
    "身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{@order.driver_id_number}"
end
```

**跟团游验证器 (v037-v040)**
```ruby
add_assertion "联系人信息正确（张三 13800138000）", weight: 5 do
  expect(@booking.contact_name).to eq('张三'),
    "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.contact_name}"
  expect(@booking.contact_phone).to eq('13800138000'),
    "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
end

# ✅ 新增：出行人验证（v037 单成人示例）
add_assertion "出行人信息正确（张三 110101199001011234）", weight: 10 do
  travelers = @booking.booking_travelers.where(data_version: @data_version)
  expect(travelers.size).to eq(1), "出行人数量错误。期望: 1人, 实际: #{travelers.size}人"
  
  traveler = travelers.first
  expect(traveler.traveler_name).to eq('张三'),
    "出行人姓名错误。期望: 张三（demo_user数据）, 实际: #{traveler.traveler_name}"
  expect(traveler.id_number).to eq('110101199001011234'),
    "出行人身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{traveler.id_number}"
  expect(traveler.traveler_type).to eq('adult'),
    "出行人类型错误。期望: adult, 实际: #{traveler.traveler_type}"
end

# ✅ v038 多成人验证（通用模式）
add_assertion "出行人信息正确（#{@adult_count}位成人）", weight: 10 do
  travelers = @booking.booking_travelers.where(data_version: @data_version, traveler_type: 'adult')
  expect(travelers.size).to eq(@adult_count),
    "成人出行人数量错误。期望: #{@adult_count}人, 实际: #{travelers.size}人"
  
  # 验证所有出行人都来自 demo_user 的 passengers
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  valid_passenger_names = user.passengers.where(data_version: 0).pluck(:name)
  
  travelers.each do |traveler|
    expect(valid_passenger_names).to include(traveler.traveler_name),
      "出行人 #{traveler.traveler_name} 不在 demo_user passengers 列表中"
    expect(traveler.id_number).not_to be_nil,
      "出行人 #{traveler.traveler_name} 缺少身份证号"
  end
end

# ✅ v040 成人+儿童验证
add_assertion "出行人信息正确（1成人张三 + 1儿童小明）", weight: 10 do
  travelers = @booking.booking_travelers.where(data_version: @data_version)
  expect(travelers.size).to eq(2), "出行人数量错误。期望: 2人, 实际: #{travelers.size}人"
  
  adults = travelers.where(traveler_type: 'adult')
  children = travelers.where(traveler_type: 'child')
  
  expect(adults.size).to eq(1), "成人出行人数量错误。期望: 1人, 实际: #{adults.size}人"
  expect(children.size).to eq(1), "儿童出行人数量错误。期望: 1人, 实际: #{children.size}人"
  
  adult = adults.first
  expect(adult.traveler_name).to eq('张三'),
    "成人出行人姓名错误。期望: 张三（demo_user数据）, 实际: #{adult.traveler_name}"
  expect(adult.id_number).to eq('110101199001011234'),
    "成人身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{adult.id_number}"
  
  child = children.first
  expect(child.traveler_name).to eq('小明'),
    "儿童出行人姓名错误。期望: 小明（demo_user数据）, 实际: #{child.traveler_name}"
  expect(child.id_number).not_to be_nil,
    "儿童出行人缺少身份证号"
end
```

**改进理由：**
- 验证数据来源于 demo_user，防止 AI Agent 硬编码任意姓名、电话
- 确保业务数据规范性

#### c) 权重调整
由于添加了新的数据规范验证断言，调整了部分原有断言的权重以保持总和=100%

**示例（v032）：**
- 租赁天数：30% → 10%（减少20%）
- 新增驾驶人信息验证：+10%
- 总和仍为100%

### 4. simulate 方法优化（所有验证器）

#### a) 添加 data_version
```ruby
# 优化前
CarOrder.create!(
  # ... 其他字段
  status: 'pending',
  total_price: total_price
)

# 优化后
CarOrder.create!(
  # ... 其他字段
  status: 'pending',
  total_price: total_price,
  data_version: @data_version  # ✅ 添加会话隔离
)
```

**改进理由：** 确保创建的订单与当前验证会话关联

#### b) 使用 demo_user 数据替代硬编码
详见"优化内容 2"

### 5. prepare 方法优化

#### task 字段更新
```ruby
# 优化前
task: "请预订一张明天从#{@origin}到#{@destination}的经济舱航班"

# 优化后
task: "给张三订一张明天从#{@origin}到#{@destination}的经济舱机票"
```

**改进理由：** 与 title 保持一致，使用用户视角的自然语言

## 优化效果

### 1. 题目更自然
- ✅ 明确受益人"张三"
- ✅ 使用口语化动词（"给...订"、"帮...租"）
- ✅ 删除表单化语言（"请预订"、"请租赁"）

### 2. 数据来源规范
- ✅ 机票/租车使用 passengers（需要身份证号）
- ✅ 跟团游使用 contacts（只需联系方式）
- ✅ 删除所有硬编码姓名、电话、身份证号

### 3. 验证更严格
- ✅ 添加 data_version 过滤（会话隔离）
- ✅ 新增数据规范验证断言
- ✅ 防止 AI Agent 使用任意数据绕过验证

### 4. 权重分配合理
- ✅ 所有验证器权重总和=100%
- ✅ 核心业务逻辑权重较高（20-30%）
- ✅ 数据规范验证权重适中（5-10%）

## 权重分配模式

### 机票验证器 (v031)
- 订单已创建：20%
- 航线正确：20%
- 出发日期正确：15%
- 舱位正确：20%
- **乘机人信息正确：25%** ← 新增
- **总和：100%**

### 租车验证器 (v032-v036)
- 订单已创建：15-30%
- 城市正确：15-30%
- 日期正确：15-20%
- 车型/价格验证：20-30%
- **驾驶人信息正确：10%** ← 新增
- **总和：100%**

### 跟团游验证器 (v037-v040)
- 订单已创建：20-25%
- 目的地正确：20-25%
- 出发日期正确：15%
- 天数正确：15-20%
- 人数/价格验证：5-20%
- **联系人信息正确：5%** ← 新增
- **出行人信息正确：10%** ← 新增（验证 booking_travelers）
- **总和：100%**

## 文档遵循检查清单

### ✅ 题目检查
- [x] 格式："给XX预订..." 或 "帮XX订..."
- [x] 包含受益人和关键约束
- [x] 删除具体地址、电话、操作步骤

### ✅ 数据引用检查
- [x] 机票乘机人使用 passengers（需要身份证号）
- [x] 租车驾驶人使用 passengers（需要身份证号）
- [x] 跟团游联系人使用 contacts（只需联系方式）
- [x] 跟团游出行人使用 passengers（需要身份证号，存入 booking_travelers 表）
- [x] 删除硬编码的姓名、电话、身份证号

### ✅ 验证断言检查
- [x] 第一条断言查询订单 + 包含 `data_version: @data_version`
- [x] 查询只过滤核心实体，不过滤待验证属性
- [x] 添加数据规范验证（乘机人/驾驶人/联系人来自 demo_user）
- [x] 添加跟团游出行人验证（booking_travelers 来自 demo_user passengers）
- [x] 权重总和 = 100%

## 重要修正记录

### 2025-02-06: 跟团游出行人信息补充

**问题发现**：初版优化只添加了联系人验证，缺少出行人（游客）验证

**问题原因**：
- 跟团游需要两种信息：
  1. **联系人**（contact_name, contact_phone）- 紧急联系人
  2. **出行人**（booking_travelers 表）- 实际游客，需要身份证号
- 初版只处理了联系人，没有创建和验证 booking_travelers

**修正内容**：
1. **simulate 方法**：添加 booking_travelers 创建逻辑
   - v037, v039: 1个成人（张三）
   - v038: 2个成人（从 passengers 表取前2个）
   - v040: 1成人（张三）+ 1儿童（小明）

2. **verify 方法**：添加出行人验证断言（权重10%）
   - 验证出行人数量
   - 验证出行人姓名、身份证号
   - 验证出行人类型（adult/child）
   - 验证出行人数据来源于 demo_user passengers

3. **权重调整**：
   - v037: 人数 10% → 5%，新增出行人验证 10%
   - v038: 成人数量 15% → 10%，新增出行人验证 10%
   - v039: 价格 25% → 20%，新增出行人验证 10%
   - v040: 人员组成 20% → 15%，新增出行人验证 10%

**为什么需要出行人表**：
- 跟团游涉及机票、酒店预订，需要实名信息
- 联系人可能不是游客本人（如家属代订）
- booking_travelers 存储所有实际出行人的身份证信息

**数据表结构**：
```ruby
# tour_group_bookings（订单表）
- contact_name          # 联系人姓名
- contact_phone         # 联系电话
- adult_count           # 成人数量
- child_count           # 儿童数量

# booking_travelers（出行人表）
- tour_group_booking_id # 关联订单
- traveler_name         # 游客姓名
- id_number             # 身份证号
- traveler_type         # 类型：adult/child
```

## 后续建议

1. **运行验证测试**
   ```bash
   rake validator:simulate_single[v031_book_economy_class_flight_hangzhou_shenzhen_validator]
   rake validator:simulate_single[v032_rent_any_car_shanghai_validator]
   # ... 依次测试 v033-v040
   ```

2. **观察改进效果**
   - 数据规范验证是否有效识别硬编码问题
   - 会话隔离是否正确工作
   - 权重分配是否合理

3. **参考本次优化经验**
   - 可将此优化模式应用于其他验证器
   - 建立验证器优化 SOP（标准操作流程）

## 相关文档

- `docs/VALIDATOR_WRITING_STANDARDS.md` - 验证器编写标准（优化依据）
- `app/validators/support/data_packs/v1/demo_user.rb` - Demo 用户数据源

## 优化完成时间
2025年

---

**优化人员备注：** 本次优化严格遵循 `VALIDATOR_WRITING_STANDARDS.md` 文档标准，确保所有验证器符合用户视角的题目格式、使用规范的 demo_user 数据、添加完整的数据规范验证断言。
