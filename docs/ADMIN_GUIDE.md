# 🛡️ 后台管理系统指南

## 📋 概述

完整的后台管理系统，用于管理航班预订系统的所有数据。

---

## 🚀 访问后台

### 登录地址

```
http://localhost:3000/admin/login
```

### 默认管理员账号

查看 `db/seeds.rb` 获取管理员账号信息。

---

## 📊 功能模块

### 1. 用户管理（Users）

**路径**：`/admin/users`

**功能**：
- ✅ 查看所有注册用户
- ✅ 用户详情查看
- ✅ 编辑用户信息
- ✅ 删除用户

**字段**：
- ID
- 邮箱
- 创建时间
- 更新时间

**操作**：
- 查看用户的所有预订记录
- 查看用户的乘客信息

---

### 2. 航班管理（Flights）

**路径**：`/admin/flights`

**功能**：
- ✅ 查看所有航班
- ✅ 创建新航班
- ✅ 编辑航班信息
- ✅ 删除航班
- ✅ 搜索航班

**字段**：
- 航班号（`flight_number`）
- 航空公司（`airline`）
- 出发城市（`departure_city`）
- 到达城市（`destination_city`）
- 出发时间（`departure_time`）
- 到达时间（`arrival_time`）
- 出发机场（`departure_airport`）
- 到达机场（`arrival_airport`）
- 机型（`aircraft_type`）
- 价格（`price`）
- 折扣价（`discount_price`）
- 座位等级（`seat_class`）
- 可用座位数（`available_seats`）
- 航班日期（`flight_date`）

**使用场景**：
- 添加新航线
- 更新航班时间
- 调整价格
- 管理座位库存

---

### 3. 预订管理（Bookings）

**路径**：`/admin/bookings`

**功能**：
- ✅ 查看所有预订记录
- ✅ 预订详情查看
- ✅ 编辑预订信息
- ✅ 取消预订
- ✅ 按状态筛选
- ✅ 按日期范围筛选

**字段**：
- 预订ID
- 用户ID（`user_id`）
- 航班ID（`flight_id`）
- 乘客姓名（`passenger_name`）
- 乘客身份证号（`passenger_id_number`）
- 联系电话（`contact_phone`）
- 总价（`total_price`）
- 订单状态（`status`）
  - `pending` - 待支付
  - `paid` - 已支付
  - `cancelled` - 已取消
  - `completed` - 已完成
- 保险类型（`insurance_type`）
- 保险价格（`insurance_price`）
- 创建时间

**使用场景**：
- 查看所有订单
- 处理退款
- 查看收入统计
- 导出订单数据

---

### 4. 乘客管理（Passengers）

**路径**：`/admin/passengers`

**功能**：
- ✅ 查看所有常用乘客
- ✅ 乘客详情查看
- ✅ 编辑乘客信息
- ✅ 删除乘客

**字段**：
- 乘客ID
- 用户ID（`user_id`）
- 姓名（`name`）
- 证件类型（`id_type`）
- 证件号码（`id_number`）
- 手机号（`phone`）
- 创建时间

**使用场景**：
- 查看用户的常用乘客列表
- 批量导入乘客信息
- 验证证件信息

---

### 5. 航班优惠管理（Flight Offers）

**路径**：`/admin/flight_offers`

**功能**：
- ✅ 查看所有优惠信息
- ✅ 创建新优惠
- ✅ 编辑优惠详情
- ✅ 删除优惠
- ✅ 设置推荐优惠

**字段**：
- 优惠ID
- 航班ID（`flight_id`）
- 供应商名称（`provider_name`）
- 优惠类型（`offer_type`）
- 价格（`price`）
- 原价（`original_price`）
- 返现金额（`cashback_amount`）
- 折扣项目（`discount_items`）
- 座位等级（`seat_class`）
- 服务内容（`services`）
- 标签（`tags`）
- 行李信息（`baggage_info`）
- 是否含餐（`meal_included`）
- 退改政策（`refund_policy`）
- 是否推荐（`is_featured`）
- 显示顺序（`display_order`）

**使用场景**：
- 创建促销活动
- 管理供应商报价
- 设置首页推荐

---

### 6. 系统管理

#### 6.1 管理员管理（Administrators）

**路径**：`/admin/administrators`

**功能**：
- ✅ 管理员账号管理
- ✅ 权限设置

#### 6.2 操作日志（Operation Logs）

**路径**：`/admin/admin_oplogs`

**功能**：
- ✅ 查看所有管理员操作记录
- ✅ 审计追踪

#### 6.3 任务队列（Job Queue）

**路径**：`/admin/good_job`

**功能**：
- ✅ 查看后台任务执行情况
- ✅ 重试失败任务
- ✅ 清理任务队列

---

## 🎯 后台管理导航

### 主菜单（MENU）

```
📊 Dashboard          - 首页概览
👥 Users             - 用户管理
✈️  Flights           - 航班管理
📝 Bookings          - 预订管理
👤 Passengers        - 乘客管理
💰 Flight Offers     - 优惠管理
```

### 系统菜单（SYSTEM）

```
👨‍💼 Administrators    - 管理员管理
📋 Operation Logs    - 操作日志
⚙️  Job Queue         - 任务队列（新窗口）
```

---

## 💡 常用操作

### 查看最新预订

1. 访问 `/admin/bookings`
2. 列表默认按创建时间倒序排列
3. 点击预订查看详情

### 创建测试航班

1. 访问 `/admin/flights`
2. 点击"New Flight"按钮
3. 填写航班信息：
   - 航班号：CZ1234
   - 出发城市：深圳
   - 到达城市：武汉
   - 出发时间：2025-01-15 10:00
   - 到达时间：2025-01-15 12:00
   - 价格：800
   - 可用座位：100
4. 点击"Create Flight"

### 查看订单统计

1. 访问 `/admin` （Dashboard）
2. 查看统计卡片：
   - 总用户数
   - 总预订数
   - 今日预订数
   - 总收入

### 处理订单退款

1. 访问 `/admin/bookings`
2. 找到需要退款的订单
3. 点击"Edit"
4. 修改状态为"cancelled"
5. 保存

---

## 🔍 搜索和筛选

### 按状态筛选预订

后台支持按状态筛选：
- 待支付（pending）
- 已支付（paid）
- 已取消（cancelled）
- 已完成（completed）

### 按日期筛选

可以筛选指定日期范围的预订。

### 搜索用户

通过邮箱搜索用户。

---

## 📊 数据导出

### 导出订单数据

```ruby
# 在 Rails console 中执行
require 'csv'

CSV.open("bookings_export.csv", "wb") do |csv|
  csv << ["ID", "用户", "航班", "乘客", "价格", "状态", "创建时间"]
  
  Booking.includes(:user, :flight).find_each do |booking|
    csv << [
      booking.id,
      booking.user.email,
      "#{booking.flight.departure_city}→#{booking.flight.destination_city}",
      booking.passenger_name,
      booking.total_price,
      booking.status,
      booking.created_at.strftime("%Y-%m-%d %H:%M")
    ]
  end
end
```

### 导出航班数据

```ruby
# 导出所有航班信息
CSV.open("flights_export.csv", "wb") do |csv|
  csv << Flight.column_names
  
  Flight.find_each do |flight|
    csv << flight.attributes.values
  end
end
```

---

## 🛠️ 批量操作

### 批量创建航班

```ruby
# db/seeds.rb 或 rails console

cities = [
  ["深圳", "武汉"],
  ["北京", "上海"],
  ["广州", "深圳"],
  ["成都", "重庆"]
]

cities.each do |departure, destination|
  Flight.create!(
    departure_city: departure,
    destination_city: destination,
    departure_time: 7.days.from_now.change(hour: 10, min: 0),
    arrival_time: 7.days.from_now.change(hour: 12, min: 0),
    flight_number: "CZ#{rand(1000..9999)}",
    airline: "南航",
    price: rand(500..1500),
    available_seats: rand(50..200),
    flight_date: 7.days.from_now.to_date
  )
end
```

### 批量更新价格

```ruby
# 所有航班打8折
Flight.where("price > ?", 500).find_each do |flight|
  flight.update(discount_price: flight.price * 0.8)
end
```

---

## 📱 响应式设计

后台管理系统支持：
- ✅ 桌面端（>1024px）：侧边栏导航
- ✅ 平板端（768-1024px）：可收起侧边栏
- ✅ 移动端（<768px）：汉堡菜单

---

## 🎨 主题切换

后台支持明暗主题切换，状态保存在 localStorage。

---

## 🔐 权限说明

当前版本：
- ✅ 管理员登录验证
- ✅ 操作日志记录
- ❌ 细粒度权限控制（待实现）

**注意**：所有管理员目前拥有完全权限。

---

## 📚 开发指南

### 添加新的管理模块

如果需要为新模型添加后台管理：

```bash
# 例如：为 Review 模型生成后台 CRUD
rails generate admin_crud Review
```

自动生成：
- ✅ Controller（`app/controllers/admin/reviews_controller.rb`）
- ✅ Views（index, show, new, edit）
- ✅ Routes
- ✅ 侧边栏菜单项
- ✅ 测试文件

### 自定义视图

生成的视图是基础模板，可以根据需要自定义：

```erb
<!-- app/views/admin/bookings/index.html.erb -->

<!-- 添加自定义筛选器 -->
<div class="mb-4">
  <%= form_with url: admin_bookings_path, method: :get, class: "flex gap-4" do |f| %>
    <%= f.select :status, 
        options_for_select([['全部', ''], ['待支付', 'pending'], ['已支付', 'paid']]),
        {}, class: "form-select" %>
    <%= f.submit "筛选", class: "btn-primary" %>
  <% end %>
</div>

<!-- 显示列表 -->
<%= render @bookings %>
```

---

## 🔍 查询技巧

### 在 Rails Console 中查询

```ruby
# 查看今日预订
Booking.where("created_at >= ?", Date.today).count

# 查看指定航线预订量
Flight.joins(:bookings)
      .where(departure_city: "深圳", destination_city: "武汉")
      .count

# 查看用户预订历史
User.find_by(email: "test@example.com").bookings

# 查看收入统计
Booking.where(status: "paid").sum(:total_price)

# 查看热门航线
Flight.joins(:bookings)
      .group(:departure_city, :destination_city)
      .order("count_all DESC")
      .count

# 查看保险购买率
total = Booking.count.to_f
with_insurance = Booking.where.not(insurance_type: "无保障").count
puts "保险购买率: #{(with_insurance / total * 100).round(2)}%"
```

---

## 📈 数据统计

### Dashboard 统计项

可以在 `app/controllers/admin/dashboard_controller.rb` 中添加统计：

```ruby
def index
  @stats = {
    total_users: User.count,
    total_bookings: Booking.count,
    total_flights: Flight.count,
    today_bookings: Booking.where("created_at >= ?", Date.today).count,
    total_revenue: Booking.where(status: "paid").sum(:total_price),
    pending_bookings: Booking.pending.count
  }
end
```

在视图中显示：

```erb
<!-- app/views/admin/dashboard/index.html.erb -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <!-- 总用户数 -->
  <div class="card">
    <div class="card-header">
      <h3>总用户数</h3>
    </div>
    <div class="card-body">
      <p class="text-3xl font-bold"><%= @stats[:total_users] %></p>
    </div>
  </div>
  
  <!-- 总预订数 -->
  <div class="card">
    <div class="card-header">
      <h3>总预订数</h3>
    </div>
    <div class="card-body">
      <p class="text-3xl font-bold"><%= @stats[:total_bookings] %></p>
    </div>
  </div>
  
  <!-- 今日预订 -->
  <div class="card">
    <div class="card-header">
      <h3>今日预订</h3>
    </div>
    <div class="card-body">
      <p class="text-3xl font-bold text-blue-600"><%= @stats[:today_bookings] %></p>
    </div>
  </div>
  
  <!-- 总收入 -->
  <div class="card">
    <div class="card-header">
      <h3>总收入</h3>
    </div>
    <div class="card-body">
      <p class="text-3xl font-bold text-green-600">¥<%= @stats[:total_revenue] %></p>
    </div>
  </div>
</div>
```

---

## 🎨 UI 组件

后台使用统一的设计系统组件：

### 按钮

```erb
<%= link_to "新建", new_admin_flight_path, class: "btn-primary" %>
<%= link_to "编辑", edit_admin_flight_path(@flight), class: "btn-secondary" %>
<%= link_to "删除", admin_flight_path(@flight), method: :delete, data: { confirm: "确定删除？" }, class: "btn-danger" %>
```

### 表单

```erb
<%= form_with model: [:admin, @flight], class: "space-y-6" do |f| %>
  <%= render 'shared/form_error_message', model: @flight %>
  
  <div class="form-group">
    <%= f.label :flight_number, class: "form-label" %>
    <%= f.text_field :flight_number, class: "form-input" %>
  </div>
  
  <div class="flex gap-4">
    <%= f.submit "保存", class: "btn-primary" %>
    <%= link_to "取消", admin_flights_path, class: "btn-secondary" %>
  </div>
<% end %>
```

### 表格

```erb
<table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
  <thead class="bg-gray-50 dark:bg-gray-800">
    <tr>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">ID</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">航班号</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">路线</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">操作</th>
    </tr>
  </thead>
  <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
    <% @flights.each do |flight| %>
      <tr>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100"><%= flight.id %></td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100"><%= flight.flight_number %></td>
        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
          <%= flight.departure_city %> → <%= flight.destination_city %>
        </td>
        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
          <%= link_to "查看", admin_flight_path(flight), class: "text-blue-600 hover:text-blue-900 mr-4" %>
          <%= link_to "编辑", edit_admin_flight_path(flight), class: "text-indigo-600 hover:text-indigo-900 mr-4" %>
          <%= link_to "删除", admin_flight_path(flight), method: :delete, data: { confirm: "确定删除？" }, class: "text-red-600 hover:text-red-900" %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

---

## 🚨 注意事项

### 数据完整性

1. **删除航班前检查**：确保没有关联的预订记录
2. **删除用户前检查**：确保没有未完成的订单
3. **修改航班信息**：注意影响已有预订

### 操作审计

所有管理员操作都会记录在 `admin_oplogs` 表中，包括：
- 操作时间
- 操作人
- 操作类型（创建/更新/删除）
- 操作对象

---

## 📱 移动端访问

后台管理系统在移动端会自动适配：
- 侧边栏变为汉堡菜单
- 表格支持横向滚动
- 操作按钮堆叠显示

---

## 🔗 相关文档

- [验证任务 API](API_GUIDE.md) - 用于大模型训练的 API
- [快速参考](../VISION_VALIDATION.md) - 验证工具快速参考

---

## 💻 开发者提示

### 自定义控制器

```ruby
# app/controllers/admin/flights_controller.rb

class Admin::FlightsController < Admin::BaseController
  before_action :set_flight, only: [:show, :edit, :update, :destroy]
  
  def index
    @flights = Flight.order(created_at: :desc).page(params[:page])
  end
  
  def show
    # 自定义逻辑
    @bookings = @flight.bookings.includes(:user)
  end
  
  def create
    @flight = Flight.new(flight_params)
    
    if @flight.save
      redirect_to admin_flight_path(@flight), notice: "航班创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_flight
    @flight = Flight.find(params[:id])
  end
  
  def flight_params
    params.require(:flight).permit(
      :departure_city, :destination_city, :departure_time,
      :arrival_time, :flight_number, :airline, :price,
      :available_seats, :flight_date
    )
  end
end
```

---

**后台管理系统已完善！** 🎉

现在你可以：
- ✅ 管理所有用户
- ✅ 管理所有航班
- ✅ 管理所有预订
- ✅ 管理所有乘客
- ✅ 管理所有优惠
- ✅ 查看操作日志
- ✅ 监控任务队列
