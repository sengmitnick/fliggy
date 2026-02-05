# 📋 V301 验证器详解：预订运动健身游

## 🎯 任务目标

**验证器ID**: `v301_book_sports_fitness_tour_validator`  
**任务描述**: 用户预订运动健身游（健身房+瑜伽课+健康餐）

---

## 📖 任务说明

### 用户需求
- 用户想要预订一个**运动健身度假**套餐
- 地点：深圳
- 时间：6天后入住，住4晚（4天5夜）
- 特殊要求：酒店必须**配备健身房和运动设施**
- 适合：健身爱好者

### 具体操作步骤

**步骤1：选择酒店** 🏨
- 在深圳找一家**配备健身房、泳池等运动设施**的酒店
- 入住日期：6天后
- 住宿时长：至少3晚（任务要求4晚）

**步骤2：创建酒店预订** ✅
- 预订选中的酒店
- 填写入住信息（姓名、电话）
- 选择房型和房间数
- 确认日期和价格

**步骤3（可选）：预订运动体验活动** 🏃
- 如果有合适的景区运动活动（如瑜伽课、健身体验等）
- 可以额外预订一个活动订单
- 活动日期：入住期间的第二天

---

## 📊 评分标准（总分100分）

| 评分项 | 权重 | 说明 |
|--------|------|------|
| **创建酒店预订** | 35% | 必须创建一个深圳的酒店预订 |
| **酒店配备健身设施** | 30% | 酒店的 `facilities` 字段包含"健身"、"游泳池"、"泳池"或"运动"关键词 |
| **创建运动活动订单** | 20% | 可选项，如果创建了 ActivityOrder 可得分（不创建也不扣分） |
| **入住日期正确** | 10% | 入住日期必须是 6 天后 |
| **住宿天数≥3晚** | 5% | 至少住3晚（实际要求是4晚） |

---

## 🔍 验证逻辑详解

### 断言1: 创建了酒店预订（35分）

```ruby
@hotel_booking = HotelBooking
  .joins(:hotel)
  .where(hotels: { city: @city })  # 深圳的酒店
  .where(data_version: @data_version)  # 当前验证器会话的数据
  .order(created_at: :desc)  # 最新创建的
  .first

expect(@hotel_booking).not_to be_nil  # 必须存在
```

**检查什么？**
- 是否创建了一个酒店预订
- 酒店是否在深圳

**如何得分？**
- 存在预订 → 35分
- 不存在 → 0分

---

### 断言2: 酒店配备健身设施（30分）

```ruby
hotel = @hotel_booking.hotel
has_fitness = hotel.facilities.to_s.match?(/健身|游泳池|泳池|运动/i)
expect(has_fitness).to be(true)
```

**检查什么？**
- 酒店的 `facilities` 字段（文本字段）
- 是否包含关键词：**健身**、**游泳池**、**泳池**、**运动**

**示例**：
```ruby
# ✅ 合格的酒店
facilities = "配备健身房、室内游泳池、桑拿房、瑜伽室"
→ 包含"健身"和"游泳池" → 得分 ✅

# ✅ 合格的酒店
facilities = "24小时健身中心、健身器材齐全"
→ 包含"健身" → 得分 ✅

# ❌ 不合格的酒店
facilities = "免费WiFi、停车场、会议室"
→ 没有运动设施关键词 → 不得分 ❌
```

**如何得分？**
- 酒店有健身设施 → 30分
- 酒店没有健身设施 → 0分

---

### 断言3: 创建了运动活动订单（20分）

```ruby
@activity_order = ActivityOrder
  .where(data_version: @data_version)
  .order(created_at: :desc)
  .first

if @activity_order
  expect(@activity_order).not_to be_nil  # 如果有，验证存在
else
  expect(true).to be(true)  # 如果没有，也算通过
end
```

**检查什么？**
- 是否创建了景区活动订单（如瑜伽课、健身体验等）

**如何得分？**
- **有活动订单** → 20分 ✅
- **没有活动订单** → 也给20分 ✅（这是**赠分项**）

> ⚠️ **注意**：这个断言的逻辑有问题，无论有没有活动订单都会给分。实际运行时这20分是白送的。

---

### 断言4: 入住日期正确（10分）

```ruby
expect(@hotel_booking.check_in_date).to eq(@check_in_date)
```

**检查什么？**
- 酒店预订的入住日期
- 必须是：**今天 + 6天**

**示例**：
```ruby
# 假设今天是 2026-02-05
@check_in_date = Date.today + 6.days  # 2026-02-11

# ✅ 正确
@hotel_booking.check_in_date = Date.parse('2026-02-11')  # 得分

# ❌ 错误
@hotel_booking.check_in_date = Date.parse('2026-02-12')  # 不得分
```

**如何得分？**
- 日期完全匹配 → 10分
- 日期不匹配 → 0分

---

### 断言5: 住宿天数≥3晚（5分）

```ruby
actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
expect(actual_nights).to be >= 3
```

**检查什么？**
- 退房日期 - 入住日期 = 住宿天数
- 必须 ≥ 3晚

**示例**：
```ruby
# ✅ 合格
check_in = 2026-02-11, check_out = 2026-02-15
→ 15 - 11 = 4晚 → 得分 ✅

# ✅ 合格
check_in = 2026-02-11, check_out = 2026-02-14
→ 14 - 11 = 3晚 → 得分 ✅

# ❌ 不合格
check_in = 2026-02-11, check_out = 2026-02-13
→ 13 - 11 = 2晚 → 不得分 ❌
```

**如何得分？**
- ≥3晚 → 5分
- <3晚 → 0分

---

## 🤖 模拟实现（simulate方法）

这是参考实现，展示了AI应该如何完成任务：

```ruby
def simulate
  # 1. 找用户
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  
  # 2. 找深圳的酒店（按评分排序）
  hotel = Hotel
    .where(city: @city, data_version: 0)
    .order(rating: :desc)  # 选评分最高的
    .first!
  
  # 3. 创建酒店预订
  HotelBooking.create!(
    hotel_room_id: hotel.hotel_rooms.first!.id,
    user_id: user.id,
    rooms_count: 1,
    adults_count: 1,
    children_count: 0,
    hotel_id: hotel.id,
    check_in_date: @check_in_date,     # 6天后
    check_out_date: @check_out_date,   # 入住+4天
    guest_name: '张先生',
    guest_phone: '13800138000',
    payment_method: '花呗',
    total_price: hotel.price * 4,  # 4晚的价格
    status: 'pending',
    data_version: @data_version  # 关键！会话隔离
  )
  
  # 4. 可选：找一个运动体验活动
  attraction = Attraction.where(city: @city, data_version: 0).first
  if attraction
    activity = attraction.attraction_activities
      .where(activity_type: 'experience', data_version: 0)
      .first
    
    if activity
      # 创建乘客信息
      passenger = Passenger.find_or_create_by!(
        user_id: user.id,
        id_number: '440300199001011234',
        data_version: @data_version
      ) do |p|
        p.name = '张先生'
        p.id_type = 'id_card'
        p.phone = '13800138000'
      end
      
      # 创建活动订单
      ActivityOrder.create!(
        user_id: user.id,
        attraction_activity_id: activity.id,
        visit_date: @visit_date,  # 入住后第二天
        quantity: 1,
        passenger_ids: [passenger.id],
        total_price: activity.current_price,
        status: 'pending',
        insurance_type: 'none',
        data_version: @data_version
      )
    end
  end
end
```

---

## ✅ 成功案例

### 满分示例（100分）

```ruby
# 用户操作流程
1. 访问深圳酒店列表页面
2. 筛选条件：配备健身房的酒店
3. 选择"深圳湾万豪酒店"（facilities包含"健身房"和"室内泳池"）
4. 填写预订信息：
   - 入住日期：2026-02-11（6天后）
   - 退房日期：2026-02-15（4晚）
   - 房间数：1间
   - 成人：1人
5. 提交预订
6. （可选）预订景区运动体验活动

# 得分
✅ 创建酒店预订：35分
✅ 酒店有健身设施：30分
✅ 创建活动订单：20分（即使不创建也给20分）
✅ 入住日期正确：10分
✅ 住宿≥3晚：5分
━━━━━━━━━━━━━━━━
总分：100分
```

---

## ❌ 常见错误

### 错误1: 选择了没有健身设施的酒店（失分30分）

```ruby
# 问题
hotel.facilities = "免费WiFi、停车场、行李寄存"
→ 没有健身相关关键词 → 失分30分

# 修复
选择 facilities 包含"健身房"、"泳池"、"运动"的酒店
```

---

### 错误2: 入住日期错误（失分10分）

```ruby
# 问题
check_in_date = Date.today + 5.days  # 5天后，不是6天后
→ 日期不匹配 → 失分10分

# 修复
check_in_date = @check_in_date  # 使用prepare方法返回的日期
```

---

### 错误3: 住宿天数不足（失分5分）

```ruby
# 问题
check_in = 2026-02-11, check_out = 2026-02-13  # 只住2晚
→ 不满足≥3晚 → 失分5分

# 修复
check_out_date = check_in_date + 4.days  # 住4晚（或至少3晚）
```

---

### 错误4: 没有创建酒店预订（失分35分）

```ruby
# 问题
只创建了活动订单，忘记创建酒店预订
→ 最核心的操作缺失 → 失分35分

# 修复
必须调用 HotelBooking.create!(...) 创建预订
```

---

## 🔑 关键点总结

### 1️⃣ **最重要**：创建酒店预订（35分）
   - 必须有一个 HotelBooking 记录
   - 酒店必须在深圳

### 2️⃣ **第二重要**：酒店配备健身设施（30分）
   - 选酒店时检查 `facilities` 字段
   - 必须包含关键词：健身、游泳池、泳池、运动

### 3️⃣ **送分项**：活动订单（20分）
   - 创不创建都给20分（逻辑BUG）
   - 建议不创建，节省时间

### 4️⃣ **细节**：入住日期（10分）
   - 必须严格等于 `Date.today + 6.days`

### 5️⃣ **最小要求**：住宿天数（5分）
   - 至少3晚，建议4晚

---

## 🎓 学习建议

1. **先看 prepare 方法** → 了解任务参数
2. **再看 verify 方法** → 了解评分标准
3. **最后看 simulate 方法** → 学习参考实现

**重点关注**：
- 哪些字段必须匹配（如 `check_in_date`）
- 哪些字段有灵活性（如活动订单可选）
- 哪些字段有文本搜索（如 `facilities` 的关键词匹配）

---

## 🚀 快速开始

### 测试这个验证器

```bash
# 运行单个验证器
rake validator:simulate_single[v301_book_sports_fitness_tour_validator]
```

### 查看任务信息

```bash
# 获取任务参数
curl -X POST http://localhost:3000/api/tasks/v301_book_sports_fitness_tour_validator/start \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📚 相关文档

- `docs/VALIDATOR_DESIGN.md` - 验证器框架设计
- `docs/VALIDATOR_ID_FORMAT_CHECK.md` - validator_id 格式规范
- `app/validators/base_validator.rb` - 基础验证器类
