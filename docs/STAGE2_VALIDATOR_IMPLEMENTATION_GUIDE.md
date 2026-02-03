# 阶段2验证器实现指南

## 📊 当前进度

### 已完成 (7/49 validators implemented - 14.3%)

**时间约束验证器示例 (3/15)**:
- ✅ V202: 预订上午航班（9:00-12:00时间窗口）
- ✅ V203: 预订下午高铁（14:00-17:00时间窗口）
- ✅ V205: 预订红眼航班（23:00-02:00跨日航班）

**价格约束验证器示例 (2/15)**:
- ✅ V217: 预订航班+酒店（总预算≤1500元）
- ✅ V228: 预订往返交通+酒店（总价最低组合优化）

**多维度约束验证器示例 (2/19)**:
- ✅ V242: 预订高评分酒店（评分≥4.5分）
- ✅ V248: (skeleton only - 待实现)

### 待实现 (42/49 validators - 85.7%)

需要基于已实现的7个示例验证器，按相同模式实现剩余42个验证器。

---

## 🎯 实现模式总结

### 模式1: 时间窗口验证器 (Time Window Validators)

**代表示例**: V202, V203, V205

**核心特征**:
1. `prepare` 阶段筛选符合时间窗口的交通工具
2. `verify` 阶段验证订单的时间属性
3. `simulate` 阶段选择时间窗口内价格最优的选项

**实现模板**:
```ruby
def prepare
  @departure_city = '城市A'
  @arrival_city = '城市B'
  @travel_date = Date.today + N.days
  @time_window_start = HH  # 小时数
  @time_window_end = HH    # 小时数
  
  # 查找交通工具（Flight/Train/Bus）
  all_vehicles = Model.where(
    departure_city: @departure_city,
    destination_city: @arrival_city,  # 或 arrival_city (Train)
    date_field: @travel_date,          # flight_date or departure_time.to_date
    data_version: 0
  )
  
  # 筛选符合时间窗口
  @available_vehicles = all_vehicles.select do |v|
    hour = v.departure_time.hour
    hour >= @time_window_start && hour < @time_window_end
  end
  
  raise "未找到符合条件的交通工具" if @available_vehicles.empty?
  
  { task: "...", requirements: {...}, hint: "..." }
end

def verify
  add_assertion "创建了交通订单", weight: 20 do
    all_bookings = BookingModel
      .joins(:vehicle_association)
      .where(vehicles: { departure_city: @departure_city, ... })
      .where(data_version: @data_version)
      .order(created_at: :desc)
      .to_a
    
    @booking = all_bookings.first
    expect(@booking).not_to be_nil, "未找到订单"
  end
  
  return if @booking.nil?
  
  add_assertion "路线正确", weight: 15 do
    expect(@booking.vehicle.departure_city).to eq(@departure_city)
    expect(@booking.vehicle.destination_city).to eq(@arrival_city)
  end
  
  add_assertion "日期正确", weight: 15 do
    expect(@booking.vehicle.travel_date).to eq(@travel_date)
  end
  
  add_assertion "时间窗口正确", weight: 30 do
    hour = @booking.vehicle.departure_time.hour
    expect(hour).to be >= @time_window_start
    expect(hour).to be < @time_window_end
  end
  
  add_assertion "订单状态有效", weight: 20 do
    expect(@booking.status).to be_in(['pending', 'paid', 'completed'])
  end
end

def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  vehicle = @available_vehicles.min_by(&:price)  # 或其他选择逻辑
  
  BookingModel.create!(
    user: user,
    vehicle: vehicle,
    # ... 必填字段
    total_price: vehicle.price,
    status: 'paid',
    data_version: @data_version
  )
end
```

**关键字段映射**:
- **Flight**: `flight_date`, `destination_city`, `price`
- **Train**: `departure_time.to_date` (使用 `.by_date(date)` scope), `arrival_city`, `price_second_class`
- **Bus**: `departure_time`, `arrival_city`, `price`

**订单模型**:
- **Flight** → `Booking` (joins: `:flight`)
- **Train** → `TrainBooking` (joins: `:train`)
- **Bus** → `BusTicketOrder` (joins: `:bus_ticket`)

---

### 模式2: 预算约束验证器 (Budget Constraint Validators)

**代表示例**: V217, V228

**核心特征**:
1. `prepare` 阶段查找多个资源（交通+酒店，或往返交通+酒店）
2. `verify` 阶段验证总价≤预算上限，或选择了最优组合
3. `simulate` 阶段遍历所有组合，找到预算内最优解

**实现模板**:
```ruby
def prepare
  @max_budget = 1500  # 或其他预算
  
  # 查找交通选项
  @available_flights = Flight.where(...).order(price: :asc)
  @available_trains = Train.where(...).order(price_second_class: :asc)
  
  # 查找酒店选项
  @available_hotels = Hotel.where(...).order(price: :asc)
  
  # 验证至少有一个组合满足预算
  cheapest_combo = calculate_cheapest_combo
  raise "最便宜组合超出预算" if cheapest_combo > @max_budget
  
  { task: "...", requirements: { max_budget: @max_budget, ... } }
end

def verify
  add_assertion "创建了交通订单", weight: 20 do
    # 查找航班或火车订单
    @transport_booking = find_transport_booking
    expect(@transport_booking).not_to be_nil
  end
  
  add_assertion "创建了酒店订单", weight: 20 do
    @hotel_booking = find_hotel_booking
    expect(@hotel_booking).not_to be_nil
  end
  
  return if @transport_booking.nil? || @hotel_booking.nil?
  
  add_assertion "总价格≤预算", weight: 40 do
    total = @transport_booking.total_price + @hotel_booking.total_price
    expect(total).to be <= @max_budget,
      "总价格: #{total}元, 预算: #{@max_budget}元"
  end
  
  add_assertion "订单状态有效", weight: 20 do
    expect(@transport_booking.status).to be_in(['pending', 'paid', 'completed'])
    expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
  end
end

def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  
  # 遍历组合，找最优解
  best_combo = find_best_combination_within_budget
  
  # 创建交通订单
  create_transport_booking(user, best_combo[:transport])
  
  # 创建酒店订单
  create_hotel_booking(user, best_combo[:hotel])
end
```

**关键逻辑**:
- 遍历所有可能的组合
- 计算总价，筛选符合预算的组合
- 在符合预算的组合中，选择性价比最高的

---

### 模式3: 评分/评价约束验证器 (Rating Constraint Validators)

**代表示例**: V242

**核心特征**:
1. `prepare` 阶段使用 `where('rating >= ?', min_rating)` 筛选
2. `verify` 阶段验证订单的评分/评价数符合要求
3. `simulate` 阶段选择评分最高或评价数最多的选项

**实现模板**:
```ruby
def prepare
  @city = '城市'
  @min_rating = 4.5
  
  @available_hotels = Hotel.where(city: @city, data_version: 0)
    .where('rating >= ?', @min_rating)
    .order(rating: :desc, price: :asc)
  
  raise "未找到符合条件的酒店" if @available_hotels.empty?
  
  { task: "...", requirements: { min_rating: @min_rating } }
end

def verify
  add_assertion "创建了酒店订单", weight: 30 do
    @booking = HotelBooking.joins(:hotel)
      .where(hotels: { city: @city })
      .where(data_version: @data_version)
      .order(created_at: :desc)
      .first
    expect(@booking).not_to be_nil
  end
  
  return if @booking.nil?
  
  add_assertion "评分≥#{@min_rating}分", weight: 50 do
    rating = @booking.hotel.rating
    expect(rating).to be >= @min_rating,
      "评分: #{rating}分, 要求: ≥#{@min_rating}分"
  end
  
  add_assertion "订单状态有效", weight: 20 do
    expect(@booking.status).to be_in(['pending', 'paid', 'completed'])
  end
end

def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  hotel = @available_hotels.first  # 已按 rating DESC 排序
  room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
  
  HotelBooking.create!(...)
end
```

---

## 📝 剩余验证器实现清单

### 第1批: 时间约束验证器 (剩余12个)

**1.1 精确时间窗口 (剩余2个)**:
- ⏳ V204: 预订傍晚大巴（18:00-20:00）
  - Model: `BusTicket`, Booking: `BusTicketOrder`
  - Pattern: 与V203类似，替换为Bus模型
- ⏳ V206: 预订最早火车（05:00-07:00）+早餐
  - Model: `Train`, Booking: `TrainBooking`
  - Pattern: 与V203类似，增加早餐要求（task描述中体现）

**1.2 时长约束 (5个)**:
- ⏳ V207: 飞行时长≤2小时
  - 计算逻辑: `(arrival_time - departure_time) / 3600 <= 2`
- ⏳ V208: 行程时间最短的高铁
  - 使用 `Train.duration` 字段（分钟），选择最小值
- ⏳ V209: 夜间卧铺火车（22:00-次日8:00）
  - Pattern: 与V205红眼航班类似，跨日筛选
- ⏳ V210: 航班转火车，中转时间≤3小时
  - 组合验证器，验证两段交通的衔接时间
- ⏳ V211: 中转时间5-8小时可市内游览
  - Pattern: 与V210相反，验证中转时间足够长

**1.3 跨日/多日约束 (5个)**:
- ⏳ V212: 深夜航班+凌晨后入住酒店（24小时前台）
  - 验证: `check_in_date` 为航班到达日期，酒店支持深夜入住
- ⏳ V213: 航班+12:00前提前入住酒店
  - 验证: `check_in_time` 或任务描述要求提前入住
- ⏳ V214: 14:00后延迟退房酒店
  - 验证: `check_out_time` 或酒店政策支持延迟退房
- ⏳ V215: 5天分住2家酒店（前2晚A+后3晚B）
  - 验证: 创建2个酒店订单，日期连续，总共5晚
- ⏳ V216: 连续多段行程（北京→上海→杭州→深圳）
  - 验证: 创建3个交通订单，城市连续，日期衔接合理

---

### 第2批: 价格约束验证器 (剩余13个)

**2.1 预算上限约束 (剩余4个)**:
- ⏳ V218: 火车票+酒店，总预算≤800元
  - Pattern: 与V217类似，替换航班为火车
- ⏳ V219: 往返航班+酒店3晚，总预算≤2000元
  - Pattern: 与V228类似，增加往返+多晚约束
- ⏳ V220: 2大1小出行套餐，总预算≤5000元
  - 验证: 创建3张票（2成人+1儿童），总价≤5000
- ⏳ V221: 7天自由行，总预算≤3000元
  - 验证: 往返交通+酒店7晚，总价≤3000

**2.2 价格段筛选 (5个)**:
- ⏳ V222: 价格500-800元/晚的中档酒店
  - 筛选: `where('price >= ? AND price <= ?', 500, 800)`
- ⏳ V223: 商务舱航班（价格≥2000元）
  - 筛选: `where('price >= ?', 2000)` 或 `seat_class = 'business'`
- ⏳ V224: 火车票+经济型酒店，单项≤300元
  - 验证: 火车票≤300 AND 酒店每晚≤300
- ⏳ V225: 豪华套餐（头等舱+五星酒店），总价≥3000元
  - 筛选: `seat_class = 'first_class'` + `star_level = 5`
- ⏳ V226: 学生出行（青年票+青旅），总预算≤300元
  - Pattern: 类似V217，极低预算约束

**2.3 价格优化约束 (剩余4个)**:
- ⏳ V227: 航班+酒店，综合性价比最高
  - 计算: `score = (rating / price)` 或其他性价比公式
- ⏳ V229: 火车票+酒店，价格/质量平衡最佳
  - Pattern: 与V227类似，替换为火车
- ⏳ V230: ≤2000元预算内服务最高档组合
  - Pattern: 在预算内，选择star_level/rating最高的
- ⏳ V231: 加100元升级商务舱或高级房
  - 验证: 对比标准选项和升级选项的价格差

---

### 第3批: 多维度组合约束 (剩余17个)

**3.1 地理位置约束 (剩余4个)**:
- ⏳ V232: 预订杭州酒店，距离西湖≤2公里
  - 筛选: `where("address LIKE ? OR district LIKE ?", '%西湖%', '%西湖%')`
- ⏳ V233: 预订北京酒店，距离火车站≤1公里
  - Pattern: 与V232类似，替换为火车站关键词
- ⏳ V234: 预订深圳CBD商务区酒店
  - 筛选: `where("district IN (?) OR address LIKE ?", ['福田区', '南山区'], '%CBD%')`
- ⏳ V235: 预订上海浦东机场≤5公里酒店
  - Pattern: 与V232类似，浦东机场关键词
- ⏳ V236: 预订黄山山景房+景区内酒店
  - 筛选: `where("address LIKE ? OR features LIKE ?", '%黄山%', '%山景%')`

**3.2 设施服务约束 (剩余3个)**:
- ⏳ V237: 预订含早餐的酒店
  - 筛选: `where("features LIKE ?", '%早餐%')` (需数据包扩展)
- ⏳ V238: 预订免费停车的酒店
  - 筛选: `where("features LIKE ?", '%停车%')`
- ⏳ V239: 预订有健身房+游泳池的酒店
  - 筛选: `where("features LIKE ? AND features LIKE ?", '%健身%', '%游泳%')`
- ⏳ V240: 预订含GPS导航+儿童座椅的租车
  - Model: `Car`, Booking: `CarOrder`
- ⏳ V241: 预订含贵宾休息室的航班
  - 筛选: `where("seat_class IN (?)", ['business', 'first_class'])`

**3.3 评分/评价约束 (剩余3个)**:
- ⏳ V243: 评价数≥100条的酒店
  - 筛选: `where('review_count >= ?', 100)` (需数据包扩展字段)
- ⏳ V244: 该城市评分最高的酒店
  - 选择: `order(rating: :desc).first`
- ⏳ V245: 新开业酒店（2024年后）
  - 筛选: `where('opening_date >= ?', Date.new(2024, 1, 1))` (需数据包扩展)
- ⏳ V246: 评分波动小的酒店（稳定服务）
  - 计算: `rating_variance` 字段或计算逻辑（需数据包扩展）

**3.4 灵活性/退改约束 (4个)**:
- ⏳ V247: 可免费取消的机票
  - 筛选: `where(cancellation_policy: 'free')` (需数据包扩展)
- ⏳ V248: 全额退款的酒店
  - Pattern: 与V247类似，酒店退款政策
- ⏳ V249: 可免费改签的火车票
  - Pattern: 与V247类似，火车票改签政策
- ⏳ V250: 到店付款的酒店（无需预付）
  - 筛选: `where(payment_method: 'pay_at_hotel')` (需数据包扩展)

---

## ⚠️ 数据包扩展需求

以下验证器需要扩展数据包字段才能完整实现:

### hotels_all.rb 需要扩展的字段:
- `features`: 设施标签数组 (V237-V239)
  - 示例: `['wifi', 'breakfast', 'parking', 'gym', 'pool']`
- `review_count`: 评价数 (V243)
- `opening_date`: 开业日期 (V245)
- `rating_variance`: 评分波动 (V246) - 可选，或在验证器中计算
- `cancellation_policy`: 退改政策 (V248)
- `payment_methods`: 支付方式 (V250)

### cars.rb 需要扩展的字段:
- `features`: 车辆配置数组 (V240)
  - 示例: `['gps', 'child_seat', 'bluetooth', 'backup_camera']`

### flights.rb 需要扩展的字段:
- `cancellation_policy`: 退改政策 (V247)
- `lounge_access`: 贵宾休息室 (V241) - 或通过 `seat_class` 推断

### trains.rb 需要扩展的字段:
- `change_policy`: 改签政策 (V249)

**建议**: 优先实现不依赖数据包扩展的验证器（约30个），然后批量扩展数据包，最后实现剩余验证器。

---

## 🚀 快速实现步骤

### Step 1: 选择一个待实现的验证器
从上面清单中选择一个 ⏳ 标记的验证器。

### Step 2: 确定验证器类型
判断属于哪种模式:
- 时间约束? → 使用模式1模板
- 预算约束? → 使用模式2模板
- 评分约束? → 使用模式3模板
- 其他? → 混合模式或参考最相似的已实现验证器

### Step 3: 复制模板并修改
1. 复制对应模式的模板代码
2. 修改城市、日期、约束条件
3. 调整查询逻辑（Model、字段名）
4. 更新断言权重分配

### Step 4: 验证实现
```bash
rails runner "V201V250::V2XXValidator.new.run_prepare"
```

### Step 5: 批量测试
```bash
rake validator:simulate
```

---

## 📊 预计工作量

- **已完成**: 7个验证器 (14.3%)
- **待实现**: 42个验证器 (85.7%)
- **预计每个验证器**: 15-30分钟
- **总预计时间**: 10-21小时

**建议分批实现**:
1. **第1批** (8小时): 实现所有不依赖数据包扩展的验证器 (~30个)
2. **数据包扩展** (2小时): 扩展 hotels_all.rb, cars.rb 等字段
3. **第2批** (4小时): 实现依赖数据包扩展的验证器 (~12个)
4. **测试与修复** (4小时): 运行 `rake validator:simulate` 并修复错误

---

## ✅ 实现验证清单

每完成一个验证器后，在清单中标记:
```
- ⏳ VXXX → ✅ VXXX: 描述
```

进度追踪:
- 时间约束: 3/15 ✅✅✅⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳
- 价格约束: 2/15 ✅✅⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳
- 多维度约束: 2/19 ✅✅⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳

**总进度**: 7/49 (14.3%)

---

## 📚 参考资源

- **已实现验证器**:
  - `app/validators/v201_v250/v202_book_morning_flight_time_window_validator.rb`
  - `app/validators/v201_v250/v217_book_flight_and_hotel_budget_1500_validator.rb`
  - `app/validators/v201_v250/v228_book_cheapest_total_price_optimize_validator.rb`
  - `app/validators/v201_v250/v242_book_high_rated_hotel_above_4_5_validator.rb`
- **阶段1验证器** (`app/validators/v101_v150/`, `v151_v200/`): 参考其他组合验证器实现
- **模型字段**: 
  - Flight: `departure_time`, `arrival_time`, `price`, `seat_class`
  - Train: `departure_time`, `arrival_time`, `duration`, `price_second_class`
  - Hotel: `rating`, `price`, `star_level`, `address`, `features`
- **文档**:
  - `docs/VALIDATOR_GENERATOR.md`: 生成器使用说明
  - `docs/STAGE2_IMPLEMENTATION_PLAN.md`: 详细实施方案
  - `docs/VALIDATOR_DESIGN.md`: 验证器设计规范
