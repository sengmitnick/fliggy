# Turbo 架构违规详细分析

## 📊 总览
- **总违规数**: 56 处
- **后端控制器违规**: 44 处（13 个文件）
- **前端控制器违规**: 12 处（9 个文件）

---

## 🔴 后端违规 (Backend Controllers)

### 1️⃣ 境外票务订单 (Abroad Ticket Orders) - 14 处违规
**文件**: `app/controllers/abroad_ticket_orders_controller.rb`

**功能**: 境外机票/车票预订和支付流程

**违规详情**:
- **Line 32-49**: `create` 方法 (7处)
  - 使用 `respond_to` 块
  - 使用 `format.html` 和 `format.json`
  - 使用 `render json:`
  
- **Line 64-70**: `process_payment` 方法 (7处)
  - 使用 `respond_to` 块
  - 使用 `format.html` 和 `format.json`
  - 使用 `render json:`

**影响功能**:
- 创建订单
- 处理支付回调

---

### 2️⃣ 航班预订 (Flight Bookings) - 1 处违规
**文件**: `app/controllers/bookings_controller.rb`

**功能**: 国内航班预订

**违规详情**:
- **Line 332**: 支付确认
  - 使用 `render json: { success: true }`

**影响功能**:
- 支付确认接口

---

### 3️⃣ 汽车票订单 (Bus Ticket Orders) - 4 处违规
**文件**: `app/controllers/bus_ticket_orders_controller.rb`

**功能**: 汽车票预订和支付

**违规详情**:
- **Line 52**: 订单创建失败
  - `render json:` 返回错误
- **Line 58**: 订单创建成功
  - `render json:` 返回成功信息
- **Line 80**: 支付成功确认
  - `render json: { success: true }`
- **Line 82**: 支付失败
  - `render json:` 返回错误

**影响功能**:
- 创建汽车票订单
- 支付确认

---

### 4️⃣ 汽车票搜索 (Bus Tickets) - 1 处违规
**文件**: `app/controllers/bus_tickets_controller.rb`

**功能**: 汽车票筛选结果计数

**违规详情**:
- **Line 30**: `count_filtered_results` 方法
  - `render json: { count: @bus_tickets.count }`

**影响功能**:
- 筛选结果数量显示

---

### 5️⃣ 深度旅行预订 (Deep Travel Bookings) - 1 处违规
**文件**: `app/controllers/deep_travel_bookings_controller.rb`

**功能**: 深度旅行产品预订支付

**违规详情**:
- **Line 80**: 支付确认
  - `render json: { success: true }`

**影响功能**:
- 支付确认

---

### 6️⃣ 航班搜索 (Flights) - 9 处违规
**文件**: `app/controllers/flights_controller.rb`

**功能**: 航班搜索和筛选

**违规详情**:
- **Line 154-158**: `filter` 方法 (3处)
  - 使用 `respond_to` 块
  - 使用 `format.turbo_stream` 和 `format.html`
  
- **Line 204-208**: `sort` 方法 (3处)
  - 使用 `respond_to` 块
  - 使用 `format.turbo_stream` 和 `format.html`
  
- **Line 227-231**: `reset_filters` 方法 (3处)
  - 使用 `respond_to` 块
  - 使用 `format.turbo_stream` 和 `format.html`

**影响功能**:
- 航班筛选
- 航班排序
- 重置筛选条件

---

### 7️⃣ 酒店预订 (Hotel Bookings) - 2 处违规
**文件**: `app/controllers/hotel_bookings_controller.rb`

**功能**: 酒店预订支付

**违规详情**:
- **Line 79**: 支付成功
  - `render json: { success: true }`
- **Line 81**: 支付失败
  - `render json:` 返回错误

**影响功能**:
- 酒店预订支付确认

---

### 8️⃣ 用户资料 (Profiles) - 3 处违规
**文件**: `app/controllers/profiles_controller.rb`

**功能**: 支付密码验证

**违规详情**:
- **Line 80**: 未设置支付密码
  - `render json:` 返回错误
- **Line 86**: 验证成功
  - `render json: { success: true }`
- **Line 88**: 验证失败
  - `render json:` 返回错误

**影响功能**:
- 支付密码验证接口

---

### 9️⃣ 跟团游预订 (Tour Group Bookings) - 1 处违规
**文件**: `app/controllers/tour_group_bookings_controller.rb`

**功能**: 跟团游支付

**违规详情**:
- **Line 71**: 支付确认
  - `render json: { success: true }`

**影响功能**:
- 跟团游支付确认

---

### 🔟 火车票预订 (Train Bookings) - 1 处违规
**文件**: `app/controllers/train_bookings_controller.rb`

**功能**: 火车票支付

**违规详情**:
- **Line 94**: 支付确认
  - `render json: { success: true }`

**影响功能**:
- 火车票支付确认

---

### 1️⃣1️⃣ 接送机服务 (Transfers) - 3 处违规
**文件**: `app/controllers/transfers_controller.rb`

**功能**: 接送机服务预订

**违规详情**:
- **Line 206**: 创建订单成功
  - `render json:` 返回成功信息
- **Line 208**: 创建订单失败
  - `render json:` 返回错误
- **Line 210**: 支付确认
  - `render json: { success: true }`

**影响功能**:
- 创建接送机订单
- 支付确认

---

### 1️⃣2️⃣ 签证订单 (Visa Orders) - 4 处违规
**文件**: `app/controllers/visa_orders_controller.rb`

**功能**: 签证服务预订和支付

**违规详情**:
- **Line 53**: 创建订单成功
  - `render json:` 返回成功信息
- **Line 60**: 创建订单失败
  - `render json:` 返回错误
- **Line 74**: 支付成功
  - `render json: { success: true }`
- **Line 76**: 支付失败
  - `render json:` 返回错误

**影响功能**:
- 创建签证订单
- 支付确认

---

## 🔵 前端违规 (Frontend Controllers)

### 1️⃣ 境外订单表单 (Abroad Order Form) - 1 处违规
**文件**: `app/javascript/controllers/abroad_order_form_controller.ts`

**违规详情**:
- **Line 50**: 使用 `fetch('/abroad_ticket_orders.json')`

**影响功能**:
- 创建境外票务订单

---

### 2️⃣ 预订控制器 (Booking) - 1 处违规
**文件**: `app/javascript/controllers/booking_controller.ts`

**违规详情**:
- **Line 225**: 使用 `fetch()` 提交支付

**影响功能**:
- 航班预订支付

---

### 3️⃣ 汽车票订单 (Bus Ticket Order) - 1 处违规
**文件**: `app/javascript/controllers/bus_ticket_order_controller.ts`

**违规详情**:
- **Line 169**: 使用 `fetch('/bus_ticket_orders')`

**影响功能**:
- 创建汽车票订单

---

### 4️⃣ 汽车票搜索 (Bus Ticket Search) - 1 处违规
**文件**: `app/javascript/controllers/bus_ticket_search_controller.ts`

**违规详情**:
- **Line 530**: 使用 `fetch()` 获取筛选结果数量

**影响功能**:
- 显示筛选结果数量

---

### 5️⃣ 城市选择器 (City Selector) - 2 处违规
**文件**: `app/javascript/controllers/city_selector_controller.ts`

**违规详情**:
- **Line 430**: `fetch('https://ipapi.co/json/')` - IP定位
- **Line 487**: `fetch('http://ip-api.com/json/?lang=zh-CN')` - IP定位

**影响功能**:
- 自动检测用户当前城市

**⚠️ 特殊情况**: 这是外部 API 调用，不属于应用内部交互

---

### 6️⃣ 日期链接 (Date Link) - 1 处违规
**文件**: `app/javascript/controllers/date_link_controller.ts`

**违规详情**:
- **Line 70**: 使用 `fetch(this.urlValue)`

**影响功能**:
- 日期切换功能

---

### 7️⃣ 无限滚动 (Infinite Scroll) - 1 处违规
**文件**: `app/javascript/controllers/infinite_scroll_controller.ts`

**违规详情**:
- **Line 77**: 使用 `fetch(url)` 加载更多内容

**影响功能**:
- 列表分页加载

---

### 8️⃣ 支付确认 (Payment Confirmation) - 2 处违规
**文件**: `app/javascript/controllers/payment_confirmation_controller.ts`

**违规详情**:
- **Line 126**: `fetch('/profile/verify_pay_password')` - 验证支付密码
- **Line 192**: `fetch()` 提交支付

**影响功能**:
- 支付密码验证
- 支付提交

---

### 9️⃣ 支付弹窗 (Payment Modal) - 1 处违规
**文件**: `app/javascript/controllers/payment_modal_controller.ts`

**违规详情**:
- **Line 84**: `preventDefault + requestSubmit` 反模式

**影响功能**:
- 支付确认弹窗

---

### 🔟 签证订单 (Visa Order) - 1 处违规
**文件**: `app/javascript/controllers/visa_order_controller.ts`

**违规详情**:
- **Line 65**: 使用 `fetch('/visa_orders')`

**影响功能**:
- 创建签证订单

---

## 🎯 修复优先级建议

### 🟢 低风险 - 可以直接修复 (11处)

这些是简单的 `respond_to` 块，只使用 `format.turbo_stream`，修复后不会影响功能：

1. ✅ `flights_controller.rb` (Line 154-231) - 3个方法
   - 只需删除 `respond_to` 包装，直接渲染 `.turbo_stream.erb`

### 🟡 中风险 - 需要测试 (31处)

这些控制器使用 `render json:` 返回支付确认或简单状态，可以改为 Turbo Stream：

2. ⚠️ 支付确认接口 (10个文件)
   - `bookings_controller.rb`
   - `bus_ticket_orders_controller.rb`
   - `deep_travel_bookings_controller.rb`
   - `hotel_bookings_controller.rb`
   - `tour_group_bookings_controller.rb`
   - `train_bookings_controller.rb`
   - `transfers_controller.rb`
   - `visa_orders_controller.rb`
   - `abroad_ticket_orders_controller.rb`
   - `profiles_controller.rb`

### 🔴 高风险 - 需要仔细评估 (12处)

这些前端使用 `fetch()` 做 AJAX 请求，修改需要重写前端逻辑：

3. ⚠️ 前端 fetch() 调用 (9个文件)
   - 需要将 fetch 改为表单提交
   - 需要修改对应的后端响应
   - 可能涉及 UI 交互流程变化

### ⚪ 可豁免 - 外部 API (2处)

4. ✓ `city_selector_controller.ts` (Line 430, 487)
   - 这是调用外部 IP 定位 API
   - 不属于应用内部交互
   - **建议**: 标记为豁免，不需要修改

---

## 💡 修复建议

### 方案 A: 保守修复（推荐）
1. 先修复 `flights_controller.rb` 的 `respond_to` 块（低风险）
2. 暂时保留其他违规，添加注释说明原因
3. 逐步迁移到 Turbo Stream 架构

### 方案 B: 激进修复
1. 全部改为 Turbo Stream 架构
2. 重写所有前端交互逻辑
3. 需要大量测试

### 方案 C: 豁免验证
1. 修改验证规则，允许支付相关接口使用 JSON
2. 保持现有架构不变
3. 在 `.clackyrules` 中记录例外情况

---

## ❓ 你的决定

请告诉我：
1. **你倾向于哪个方案？**
2. **是否有特定功能不能修改？**（例如支付流程）
3. **是否允许我豁免某些类型的违规？**（例如外部 API 调用、支付确认接口）
