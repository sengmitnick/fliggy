# 大模型视觉训练任务表格

参考 AndroidWorld 论文格式，定义航班预订的视觉训练任务。

---

## 任务定义表格

| 任务昵称 | 任务模板 | 初始化逻辑 | 成功评估代码 |
|---------|---------|------------|-------------|
| **BookFlightBasic**<br/>基础预订 | 帮我订 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票 | 创建测试用户账号。添加多条航班记录（包含目标路线和其他路线作为噪音）。添加其他用户的预订记录作为噪音。记录当前用户的初始预订数量。 | `new_booking = Booking.where(user_id: user_id).order(created_at: :desc).first` <br/> `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.status == "paid"` |
| **BookFlightWithPassenger**<br/>指定乘客信息 | 帮我订 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票，乘客姓名 `{name}`，手机号 `{phone}` | 创建测试用户账号。添加同一路线但不同日期的多条航班记录。添加其他路线的航班作为噪音。记录初始预订数量。 | `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.status == "paid"` |
| **BookFlightWithPassenger**<br/>指定乘客信息 | 帮我订 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票，乘客姓名 `{name}`，手机号 `{phone}` | 创建测试用户账号。添加目标航班和噪音航班。记录初始状态。 | `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.passenger_name == params[:name] && new_booking.contact_phone == params[:phone] && new_booking.status == "paid"` |
| **BookFlightWithInsurance**<br/>购买保险 | 帮我订 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票，要买保险 | 创建测试用户账号。添加目标航班。记录初始状态。大模型需要在保险推荐弹窗中选择购买保险。 | `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.insurance_type != "无保障" && new_booking.insurance_price > 0 && new_booking.status == "paid"` |
| **BookFlightNoInsurance**<br/>不买保险 | 帮我订 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票，不要买保险 | 创建测试用户账号。添加目标航班。记录初始状态。大模型需要在保险推荐弹窗中拒绝购买保险。 | `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.insurance_type == "无保障" && new_booking.status == "paid"` |
| **FillBookingFormOnly**<br/>仅填表单 | 帮我填写 `{date}` 从 `{departure_city}` 到 `{arrival_city}` 的机票预订表单，不用支付 | 创建测试用户账号。添加目标航班。记录初始状态。 | `new_booking.flight.departure_city == params[:departure_city] && new_booking.flight.arrival_city == params[:arrival_city] && new_booking.flight.departure_time.to_date == Date.parse(params[:date]) && new_booking.status == "pending"` |

---

## 任务复杂度分析

### 简单任务（1-2 分钟）

**BookFlightBasic**（基础预订）
- 步骤数：6-7步
- 交互元素：日期选择器、搜索框、按钮、表单、弹窗
- 成功率预期：>80%

### 中等任务（2-4 分钟）

**BookFlightWithPassenger**（指定乘客）
- 步骤数：6-8步
- 交互元素：搜索框、按钮、多个输入框、弹窗
- 成功率预期：60-80%

### 复杂任务（4-6 分钟）

**BookFlightWithInsurance**（购买保险）
- 步骤数：7-9步
- 交互元素：搜索框、按钮、表单、保险选择卡片、弹窗、支付
- 决策点：需要主动选择保险产品
- 成功率预期：40-60%

**BookFlightNoInsurance**（拒绝保险）
- 步骤数：7-9步
- 交互元素：搜索框、按钮、表单、弹窗（需拒绝）、支付
- 决策点：需要正确处理保险推荐弹窗（选择"放弃"）
- 成功率预期：40-60%

### 简化任务（1-2 分钟）

**FillBookingFormOnly**（仅填表单）
- 步骤数：4-5步
- 交互元素：搜索框、按钮、表单
- 无需支付环节
- 成功率预期：>90%

---

## 任务验证示例代码

### Ruby 实现

```ruby
# 创建验证器
validator = FlightBookingTaskValidator.new(
  user_id: 1,
  departure_city: "深圳",
  arrival_city: "武汉",
  departure_date: "2025-01-15",
  should_complete_payment: true
)

# 记录初始状态（任务开始前）
validator.record_initial_state

# === 大模型执行任务 ===
# ...

# 验证结果（任务完成后）
result = validator.result

if result[:valid]
  puts "✅ 任务成功"
else
  puts "❌ 任务失败"
  result[:errors].each { |e| puts "  - #{e}" }
end
```

### Python 伪代码实现

```python
class FlightBookingTaskValidator:
    def __init__(self, task_params):
        self.task_params = task_params
        self.initial_count = None
    
    def record_initial_state(self):
        """记录任务开始前的预订数量"""
        self.initial_count = db.query(
            "SELECT COUNT(*) FROM bookings WHERE user_id = ?",
            self.task_params['user_id']
        )[0]
    
    def validate(self):
        """验证任务是否成功"""
        # 1. 检查是否有新预订
        current_count = db.query(
            "SELECT COUNT(*) FROM bookings WHERE user_id = ?",
            self.task_params['user_id']
        )[0]
        
        if current_count <= self.initial_count:
            return False, ["未创建新的预订记录"]
        
        # 2. 获取最新预订
        booking = db.query(
            """SELECT b.*, f.departure_city, f.arrival_city, f.departure_time
               FROM bookings b
               JOIN flights f ON b.flight_id = f.id
               WHERE b.user_id = ?
               ORDER BY b.created_at DESC
               LIMIT 1""",
            self.task_params['user_id']
        )[0]
        
        errors = []
        
        # 3. 验证航班路线
        if booking['departure_city'] != self.task_params['departure_city']:
            errors.append(f"出发城市不匹配")
        
        if booking['arrival_city'] != self.task_params['arrival_city']:
            errors.append(f"到达城市不匹配")
        
        # 4. 验证日期（如果指定）
        if 'departure_date' in self.task_params:
            expected_date = datetime.strptime(self.task_params['departure_date'], '%Y-%m-%d').date()
            actual_date = booking['departure_time'].date()
            if actual_date != expected_date:
                errors.append(f"出发日期不匹配")
        
        # 5. 验证支付状态
        if self.task_params.get('should_complete_payment', True):
            if booking['status'] != 'paid':
                errors.append(f"预订未完成支付")
        
        return len(errors) == 0, errors

# 使用示例
validator = FlightBookingTaskValidator({
    'user_id': 1,
    'departure_city': '深圳',
    'arrival_city': '武汉',
    'departure_date': '2025-01-15',
    'should_complete_payment': True
})

validator.record_initial_state()

# 大模型执行任务...
model.execute_task("帮我订1月15日从深圳到武汉的机票")

# 验证结果
success, errors = validator.validate()
if success:
    print("✅ 任务成功")
else:
    print("❌ 任务失败:")
    for error in errors:
        print(f"  - {error}")
```

---

## 噪音数据示例

```ruby
# 为用户 ID=1 创建测试环境

# 目标航班（应该被选择）
target_flight = Flight.create!(
  flight_number: "G2707",
  departure_city: "深圳",
  arrival_city: "武汉",
  departure_time: "2025-01-15 10:00",
  arrival_time: "2025-01-15 12:30",
  price: 582.5
)

# 噪音航班 1：不同路线
Flight.create!(
  flight_number: "G1234",
  departure_city: "北京",
  arrival_city: "上海",
  departure_time: "2025-01-15 10:00",
  price: 500
)

# 噪音航班 2：相同路线但不同日期
Flight.create!(
  flight_number: "G2708",
  departure_city: "深圳",
  arrival_city: "武汉",
  departure_time: "2025-01-16 10:00",
  price: 582.5
)

# 噪音预订：其他用户的预订
Booking.create!(
  user_id: 999,
  flight: target_flight,
  passenger_name: "李四",
  status: :paid
)

# 噪音预订：当前用户的历史预订
Booking.create!(
  user_id: 1,
  flight_id: Flight.where(departure_city: "北京").first.id,
  passenger_name: "张三",
  created_at: 1.day.ago,
  status: :completed
)
```

验证器会忽略所有噪音数据，只检查：
- 用户 ID = 1
- 任务开始后创建的预订
- 航班路线匹配目标城市

---

## 评估指标

| 指标 | 说明 | 计算方式 |
|------|------|---------|
| **任务成功率** | 成功完成的任务占比 | 成功任务数 / 总任务数 × 100% |
| **平均完成时间** | 完成一个任务的平均耗时 | 总耗时 / 成功任务数 |
| **首次成功率** | 第一次尝试就成功的占比 | 首次成功数 / 总任务数 × 100% |
| **错误类型分布** | 各类错误的占比 | 某类错误数 / 总错误数 × 100% |

### 常见错误类型

1. **路线错误**：选择了错误的出发/到达城市
2. **日期错误**：选择了错误的出发日期
3. **信息缺失**：乘客姓名或手机号未填写
4. **保险错误**：保险选择与要求不符
5. **支付未完成**：未完成支付流程
6. **无新记录**：未创建任何预订记录

---

## 与 AndroidWorld 对比

| 维度 | AndroidWorld | 本项目 |
|------|-------------|--------|
| **平台** | Android 应用 | Web 应用 |
| **任务示例** | "在 VLC 创建播放列表" | "预订深圳到武汉的机票" |
| **验证方式** | `execute_sql(vlc.query) == files` | `booking.departure_city == "深圳"` |
| **噪音数据** | 无关音乐文件 | 其他路线航班、其他用户预订 |
| **任务粒度** | 单个应用操作 | 完整业务流程（多步骤） |
| **交互复杂度** | 中等（触摸、滑动） | 中等偏高（表单、弹窗、支付） |

---

## 总结

本验证框架专为**大模型视觉能力训练**设计：

1. ✅ **任务明确**：给模型一个自然语言指令
2. ✅ **验证简单**：只检查数据库最终结果
3. ✅ **噪音干扰**：包含大量无关数据测试鲁棒性
4. ✅ **可扩展**：轻松添加新任务类型

模型需要具备：
- 视觉理解（识别UI元素）
- 任务规划（分解步骤）
- 交互能力（点击、输入）
- 异常处理（处理弹窗、错误）

最终只要数据库里有正确的预订记录，就认为任务成功完成。
