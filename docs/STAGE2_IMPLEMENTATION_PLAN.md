# 阶段2实施方案：条件变体验证器 (V171-V220, +50个)

## 📋 总体规划

**目标**: 170→220 (+50个验证器)  
**策略**: 条件变体验证器（复杂约束条件，无需新增数据包）  
**时间**: 1天  
**数据支持**: ✅ 利用现有数据包，通过不同维度筛选生成变体

---

## 🎯 核心理念

### 什么是条件变体验证器？

在现有数据基础上，通过**复杂条件组合**创建高难度决策场景：

**示例对比**:

| 类型 | V001 (简单) | V171 (复杂) |
|------|-------------|-------------|
| **任务** | 预订后天深圳到北京的低价机票 | 预订后天深圳到北京的机票，要求：<br>1. 起飞时间9:00-12:00<br>2. 价格≤800元<br>3. 直飞（非中转）<br>4. 经济舱有座 |
| **筛选维度** | 1个（价格） | 4个（时间+价格+航线+座位） |
| **决策难度** | ⭐ 简单 | ⭐⭐⭐⭐ 复杂 |
| **AI能力要求** | 价格排序 | 多条件筛选+权衡取舍 |

---

## 📦 验证器分类体系

### 第1批: 时间约束验证器 (V171-V185, 15个)

#### 1.1 精确时间窗口 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V171** | `book_morning_flight_time_window` | 预订明天**9:00-12:00**深圳→北京航班（商务出行） |
| **V172** | `book_afternoon_train_time_window` | 预订后天**14:00-17:00**上海→杭州高铁（下午茶时段出发） |
| **V173** | `book_evening_bus_time_window` | 预订明天**18:00-20:00**广州→深圳大巴（下班后出行） |
| **V174** | `book_midnight_flight_red_eye` | 预订后天**23:00-02:00**红眼航班+机场休息室 |
| **V175** | `book_sunrise_train_early_bird` | 预订明天**05:00-07:00**最早班次火车+早餐 |

**验证点**:
- 起飞/出发时间在指定窗口内
- 时间窗口外的选项应被排除
- 如果无符合选项，应选择最接近的

**数据支持**: ✅ `flights.rb` / `trains.rb` / `bus_tickets.rb` 已包含时间信息

---

#### 1.2 时长约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V176** | `book_short_haul_flight_under_2h` | 预订后天深圳→上海航班，**飞行时长≤2小时** |
| **V177** | `book_fastest_train_shortest_duration` | 预订明天上海→杭州，**行程时间最短**的高铁 |
| **V178** | `book_overnight_train_sleeper` | 预订后天北京→西安，**夜间卧铺**（22:00-次日8:00） |
| **V179** | `book_quick_connection_transfer` | 预订明天航班转火车，**中转时间≤3小时** |
| **V180** | `book_long_layover_city_tour` | 预订后天航班，**中转时间5-8小时**可市内游览 |

**验证点**:
- 计算并验证实际飞行/行驶时长
- 优先选择符合时长要求的选项
- 考虑中转时间的合理性

**数据支持**: ✅ 可通过出发/到达时间计算

---

#### 1.3 跨日/多日约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V181** | `book_hotel_check_in_after_midnight` | 预订深夜航班+**凌晨后入住酒店**（24小时前台） |
| **V182** | `book_early_check_in_hotel_before_noon` | 预订航班+酒店，**12:00前提前入住** |
| **V183** | `book_late_check_out_hotel_after_2pm` | 预订酒店，**14:00后延迟退房**（适合晚班航班） |
| **V184** | `book_split_stay_two_hotels` | 预订5天行程，**分住2家酒店**（前2晚A酒店+后3晚B酒店） |
| **V185** | `book_consecutive_trips_multi_destination` | 预订**连续多段行程**（北京→上海→杭州→深圳，4天） |

**验证点**:
- 入住/退房时间符合特殊要求
- 多酒店/多段行程的时间衔接合理
- 考虑换酒店/换城市的缓冲时间

**数据支持**: ✅ `hotels_all.rb` / `flights.rb` / `trains.rb` 已支持

---

### 第2批: 价格约束验证器 (V186-V200, 15个)

#### 2.1 预算上限约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V186** | `book_flight_and_hotel_budget_1500` | 预订航班+酒店，**总预算≤1500元** |
| **V187** | `book_train_and_hotel_budget_800` | 预订火车票+酒店，**总预算≤800元** |
| **V188** | `book_round_trip_budget_2000` | 预订往返航班+酒店3晚，**总预算≤2000元** |
| **V189** | `book_family_trip_budget_5000` | 预订2大1小出行套餐，**总预算≤5000元** |
| **V190** | `book_week_trip_budget_3000` | 预订7天自由行（往返交通+酒店），**总预算≤3000元** |

**验证点**:
- 所有订单总价≤预算上限
- 在预算内选择最优组合（性价比）
- 考虑隐藏费用（保险、接送等）

**数据支持**: ✅ 所有数据包均包含价格信息

---

#### 2.2 价格段筛选 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V191** | `book_mid_range_hotel_500_800` | 预订酒店，**价格区间500-800元/晚**（中档舒适） |
| **V192** | `book_premium_flight_business_class` | 预订商务舱航班，**价格≥2000元**（高端出行） |
| **V193** | `book_budget_combo_under_500` | 预订火车票+经济型酒店，**单项≤300元** |
| **V194** | `book_luxury_package_over_3000` | 预订豪华套餐（头等舱+五星酒店），**总价≥3000元** |
| **V195** | `book_student_budget_under_300` | 预订学生出行（青年票+青旅），**总预算≤300元** |

**验证点**:
- 价格在指定区间内
- 避免"便宜但不符合要求"的选项
- 考虑价格与服务质量的平衡

**数据支持**: ✅ 所有数据包均包含价格+星级/等级信息

---

#### 2.3 价格优化约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V196** | `book_best_value_flight_hotel_combo` | 预订航班+酒店，**综合性价比最高**（价格×评分） |
| **V197** | `book_cheapest_total_price_optimize` | 预订往返交通+酒店，**总价最低组合** |
| **V198** | `book_balanced_price_quality_ratio` | 预订火车票+酒店，**价格/质量平衡最佳** |
| **V199** | `book_premium_within_budget_max` | 预订≤2000元预算内，**服务最高档的组合** |
| **V200** | `book_incremental_upgrade_100_more` | 预订经济舱+标准房，**加100元升级商务舱或高级房** |

**验证点**:
- 需要计算综合指标（价格×评分×便利性）
- 对比多个候选方案
- 权衡取舍决策（价格 vs 质量）

**数据支持**: ✅ 数据包包含 `price` + `rating` + `star_level` 等字段

---

### 第3批: 多维度组合约束 (V201-V220, 20个)

#### 3.1 地理位置约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V201** | `book_hotel_near_landmark_west_lake` | 预订杭州酒店，**距离西湖≤2公里** |
| **V202** | `book_hotel_near_transport_hub_station` | 预订北京酒店，**距离火车站≤1公里** |
| **V203** | `book_hotel_cbd_business_district` | 预订深圳酒店，**位于CBD商务区**（福田/南山） |
| **V204** | `book_airport_hotel_within_5km` | 预订上海酒店，**距离浦东机场≤5公里** |
| **V205** | `book_scenic_area_hotel_mountain_view` | 预订黄山酒店，**山景房+景区内** |

**验证点**:
- 酒店地址包含关键词或区域名称
- 距离计算（如有经纬度数据）
- 位置便利性评估

**数据支持**: ✅ `hotels_all.rb` 包含 `address` / `district` 字段

---

#### 3.2 设施服务约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V206** | `book_hotel_with_breakfast_included` | 预订酒店，**含早餐** |
| **V207** | `book_hotel_with_parking_free` | 预订酒店，**免费停车** |
| **V208** | `book_hotel_with_gym_pool_facilities` | 预订酒店，**健身房+游泳池** |
| **V209** | `book_car_with_gps_child_seat` | 预订租车，**GPS导航+儿童座椅** |
| **V210** | `book_flight_with_lounge_access` | 预订航班，**含贵宾休息室** |

**验证点**:
- 酒店/车辆/服务包含指定设施
- 从描述或标签中识别设施
- 优先选择设施完备的选项

**数据支持**: ⚠️ 部分需要扩展
  - ✅ `hotel_packages.rb` 包含设施信息
  - ⚠️ 需要在 `hotels_all.rb` 中添加设施标签字段

---

#### 3.3 评分/评价约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V211** | `book_high_rated_hotel_above_4_5` | 预订酒店，**评分≥4.5分** |
| **V212** | `book_well_reviewed_hotel_100_plus` | 预订酒店，**评价数≥100条** |
| **V213** | `book_top_rated_in_city_best_hotel` | 预订**该城市评分最高**的酒店 |
| **V214** | `book_new_hotel_recent_opening_2024` | 预订**新开业酒店**（2024年后） |
| **V215** | `book_consistent_rating_stable_service` | 预订**评分波动小**的酒店（稳定服务） |

**验证点**:
- 评分/评价数符合条件
- 排序选择最优选项
- 考虑评价时效性（新vs旧）

**数据支持**: ✅ `hotels_all.rb` 包含 `rating` 字段

---

#### 3.4 灵活性/退改约束 (5个)

| 编号 | 验证器名称 | 核心约束 |
|------|------------|----------|
| **V216** | `book_flexible_ticket_free_cancellation` | 预订**可免费取消**的机票 |
| **V217** | `book_refundable_hotel_full_refund` | 预订**全额退款**的酒店 |
| **V218** | `book_changeable_train_reschedule_free` | 预订**可免费改签**的火车票 |
| **V219** | `book_insurance_included_full_protection` | 预订**含保险**的出行套餐 |
| **V220** | `book_pay_at_hotel_no_prepayment` | 预订**到店付款**的酒店（无需预付） |

**验证点**:
- 退改政策符合要求
- 保险/保障条款存在
- 支付方式灵活性

**数据支持**: ⚠️ 需要扩展
  - ✅ 部分数据包已有退改政策字段
  - ⚠️ 需要在主要模型中添加 `cancellation_policy` / `refund_policy` 字段

---

## 🛠️ 实施细节

### 数据包扩展需求

| 数据包文件 | 当前状态 | 需要补充字段 | 优先级 |
|-----------|---------|------------|--------|
| `flights.rb` | ✅ 完整 | （无需补充） | - |
| `trains.rb` | ✅ 完整 | （无需补充） | - |
| `hotels_all.rb` | ⚠️ 部分 | `facilities` (设施标签)<br>`cancellation_policy` (退改政策)<br>`payment_methods` (支付方式) | 中 |
| `cars.rb` | ⚠️ 部分 | `features` (车辆配置)<br>`insurance_options` (保险选项) | 低 |
| `bus_tickets.rb` | ✅ 完整 | （无需补充） | - |
| `hotel_packages.rb` | ✅ 完整 | （已包含设施信息） | - |

---

### 验证器生成策略

#### 策略1: 多条件AND组合

**模式**: 条件1 AND 条件2 AND 条件3

**示例 (V171)**:
```
预订明天深圳→北京航班，要求：
1. 起飞时间9:00-12:00
2. 价格≤800元
3. 直飞（非中转）
4. 经济舱有座
```

**verify方法结构**:
```ruby
def verify
  add_assertion "创建了航班订单", weight: 20 do
    @booking = Booking.where(...).first
    expect(@booking).not_to be_nil
  end
  
  add_assertion "起飞时间在9:00-12:00", weight: 20 do
    hour = @booking.flight.departure_time.hour
    expect(hour).to be >= 9
    expect(hour).to be < 12
  end
  
  add_assertion "价格≤800元", weight: 20 do
    expect(@booking.total_price).to be <= 800
  end
  
  add_assertion "直飞航班（非中转）", weight: 20 do
    expect(@booking.flight.stops).to eq(0)
  end
  
  add_assertion "经济舱", weight: 20 do
    expect(@booking.seat_class).to eq('economy')
  end
end
```

---

#### 策略2: 优化目标组合

**模式**: 在满足约束条件下，优化某个目标

**示例 (V196)**:
```
预订航班+酒店，综合性价比最高（价格×评分）
```

**verify方法结构**:
```ruby
def verify
  add_assertion "创建了航班+酒店订单", weight: 20 do
    @flight_booking = Booking.where(...).first
    @hotel_booking = HotelBooking.where(...).first
    expect(@flight_booking).not_to be_nil
    expect(@hotel_booking).not_to be_nil
  end
  
  add_assertion "选择了性价比较高的航班", weight: 20 do
    # 计算所选航班的性价比
    selected_ratio = @flight_booking.flight.rating / @flight_booking.total_price
    
    # 计算所有候选航班的性价比
    all_ratios = @available_flights.map { |f| f.rating / f.price }
    max_ratio = all_ratios.max
    
    # 允许5%误差
    expect(selected_ratio).to be >= max_ratio * 0.95
  end
  
  add_assertion "选择了性价比较高的酒店", weight: 20 do
    # 同理计算酒店性价比
  end
  
  add_assertion "综合性价比最优", weight: 40 do
    total_price = @flight_booking.total_price + @hotel_booking.total_price
    avg_rating = (@flight_booking.flight.rating + @hotel_booking.hotel.rating) / 2.0
    selected_ratio = avg_rating / total_price
    
    # 计算所有组合的性价比（暴力枚举前10个组合）
    # ...
  end
end
```

---

#### 策略3: 区间约束组合

**模式**: 字段值在指定区间内

**示例 (V191)**:
```
预订酒店，价格区间500-800元/晚（中档舒适）
```

**verify方法结构**:
```ruby
def verify
  add_assertion "创建了酒店订单", weight: 30 do
    @hotel_booking = HotelBooking.where(...).first
    expect(@hotel_booking).not_to be_nil
  end
  
  add_assertion "价格在500-800元区间", weight: 40 do
    price = @hotel_booking.hotel_room.price
    expect(price).to be >= 500, "价格过低（#{price}元），应选择500-800元的中档酒店"
    expect(price).to be <= 800, "价格过高（#{price}元），应选择500-800元的中档酒店"
  end
  
  add_assertion "酒店档次适中（3-4星）", weight: 30 do
    star = @hotel_booking.hotel.star_level
    expect(star).to be >= 3
    expect(star).to be <= 4
  end
end
```

---

## 📊 权重分配原则

### 标准权重分配 (5-6个断言)

| 断言类型 | 权重 | 说明 |
|---------|------|------|
| 订单存在性 | 20-25% | 基础断言（创建了订单） |
| 核心约束1 | 20% | 最重要的约束条件 |
| 核心约束2 | 20% | 第二重要的约束 |
| 核心约束3 | 15% | 第三重要的约束 |
| 辅助约束1 | 10% | 辅助条件 |
| 辅助约束2 | 10% | 辅助条件 |
| **合计** | **100%** | |

### 复杂权重分配 (7-8个断言)

| 断言类型 | 权重 | 说明 |
|---------|------|------|
| 订单存在性 | 15-20% | 基础断言 |
| 核心约束1 | 15% | 最重要的约束 |
| 核心约束2 | 15% | 第二重要的约束 |
| 核心约束3 | 15% | 第三重要的约束 |
| 辅助约束1 | 10% | 辅助条件 |
| 辅助约束2 | 10% | 辅助条件 |
| 辅助约束3 | 10% | 辅助条件 |
| 综合优化 | 10% | 综合评估 |
| **合计** | **100%** | |

---

## 🎯 实施步骤

### Step 1: 数据包补充 (4小时)

1. **hotels_all.rb 扩展** (2小时)
   - 添加 `facilities` 字段（JSON数组）
   - 添加 `cancellation_policy` 字段（string）
   - 添加 `payment_methods` 字段（JSON数组）
   
2. **cars.rb 扩展** (1小时)
   - 添加 `features` 字段（JSON数组）
   - 添加 `insurance_options` 字段（JSON数组）

3. **测试数据加载** (1小时)
   - 运行 `rake validator:reset_baseline`
   - 验证新字段数据正确性

---

### Step 2: 验证器批量生成 (4小时)

#### 第1批: 时间约束 (V171-V185, 1.5小时)
```bash
rails g validator book_morning_flight_time_window "预订明天9:00-12:00深圳→北京航班" "预订明天从深圳到北京的航班，要求起飞时间在9:00-12:00之间（商务出行时段）"
rails g validator book_afternoon_train_time_window "预订后天14:00-17:00上海→杭州高铁" "预订后天从上海到杭州的高铁，要求出发时间在14:00-17:00之间（下午茶时段）"
# ... 其他13个
```

#### 第2批: 价格约束 (V186-V200, 1.5小时)
```bash
rails g validator book_flight_and_hotel_budget_1500 "预订航班+酒店总预算≤1500元" "预订明天从北京到上海的航班和酒店1晚，要求航班+酒店总价格不超过1500元"
# ... 其他14个
```

#### 第3批: 多维度约束 (V201-V220, 1小时)
```bash
rails g validator book_hotel_near_landmark_west_lake "预订杭州西湖附近酒店" "预订杭州酒店1晚，要求距离西湖景区≤2公里"
# ... 其他19个
```

---

### Step 3: 验证器实现 (8小时)

**每个验证器平均10分钟**，包括：
1. 编写 `prepare` 方法（筛选数据）
2. 编写 `verify` 方法（5-7个断言）
3. 编写 `simulate` 方法（模拟用户行为）
4. 测试验证器通过 `rake validator:simulate`

**并行实施**:
- 时间约束验证器 (V171-V185): 3小时
- 价格约束验证器 (V186-V200): 3小时
- 多维度约束验证器 (V201-V220): 2小时

---

### Step 4: 测试与调优 (4小时)

1. **单个验证器测试** (2小时)
   ```bash
   rake validator:simulate  # 测试所有验证器
   ```
   - 检查每个验证器通过率
   - 修复失败的验证器
   
2. **批量测试** (1小时)
   ```bash
   # 测试V171-V185
   rake validator:test_range[171,185]
   # 测试V186-V200
   rake validator:test_range[186,200]
   # 测试V201-V220
   rake validator:test_range[201,220]
   ```

3. **性能优化** (1小时)
   - 优化数据查询（避免N+1）
   - 优化断言逻辑（避免重复计算）

---

## 📈 时间线

| 时间段 | 任务 | 产出 | 累计 |
|-------|------|------|------|
| **0-4h** | 数据包补充+测试 | 扩展字段+数据验证 | - |
| **4-8h** | 批量生成验证器 | 50个验证器骨架 | 50个 |
| **8-16h** | 实现验证器逻辑 | 完整的验证器实现 | 50个 |
| **16-20h** | 测试与调优 | 100%通过测试 | 50个 |
| **总计** | **20小时 (2.5天)** | **V171-V220** | **+50个** |

---

## ✅ 交付标准

### 必须满足的条件

1. ✅ 所有50个验证器通过 `rake validator:simulate`
2. ✅ 每个验证器包含5-7个断言，权重总和=100%
3. ✅ 所有验证器有清晰的 `title` 和 `description`
4. ✅ 数据包扩展字段已添加并测试通过
5. ✅ 文档完整（本文档+注释）

### 验收测试

```bash
# 测试所有验证器通过
rake validator:simulate

# 验证验证器数量
find app/validators -name 'v*_validator.rb' | grep -E 'v[0-9]+_' | wc -l
# 期望输出: 220

# 验证V171-V220存在
ls app/validators/v151_v200/ | grep 'v1[7-9][0-9]\|v200'
# 期望输出: 30个文件

ls app/validators/v201_v250/ | grep 'v20[0-9]\|v21[0-9]\|v220'
# 期望输出: 20个文件
```

---

## 🎯 关键成功因素

### 1. 数据包质量
- 确保新增字段数据完整、真实
- 测试数据加载无错误
- 字段命名规范一致

### 2. 验证器质量
- 断言逻辑清晰、准确
- 错误信息详细、有帮助
- 权重分配合理

### 3. 测试覆盖
- 每个验证器至少运行1次 `simulate`
- 边界条件测试（无符合条件的数据）
- 性能测试（查询时间≤1秒）

---

## 📊 预期收益

完成阶段2后，验证器体系将达到：

| 指标 | 阶段1 | 阶段2 | 提升 |
|------|-------|-------|------|
| 验证器总数 | 170个 | 220个 | +29% |
| 复杂度 | ⭐⭐⭐ | ⭐⭐⭐⭐ | +33% |
| 约束维度 | 2-3个 | 4-6个 | +100% |
| AI决策难度 | 中等 | 困难 | +50% |
| 真实场景覆盖 | 85% | 95% | +12% |

---

## 🚀 下一步行动

### 立即开始
1. 阅读本文档并理解实施策略
2. 准备数据包扩展（Step 1）
3. 批量生成验证器骨架（Step 2）

### 并行推进
- 前端：数据包扩展 + 测试
- 后端：验证器实现 + 调优
- 测试：持续运行 `rake validator:simulate`

### 里程碑检查
- 4小时后：数据包扩展完成 ✅
- 8小时后：50个验证器骨架完成 ✅
- 16小时后：所有验证器实现完成 ✅
- 20小时后：100%测试通过 ✅

---

## 📝 备注

### 风险与应对

| 风险 | 应对措施 |
|------|---------|
| 数据包字段扩展失败 | 先在测试环境验证，再应用到生产环境 |
| 验证器通过率低 | 降低约束条件的严格程度，或增加候选数据 |
| 实施时间超出预期 | 优先完成前2批（V171-V200），第3批可延后 |
| 数据包数据不足 | 临时生成补充数据，或放宽部分约束条件 |

---

## ✅ 结论

阶段2将通过**条件变体验证器**，在**不大幅增加数据包**的情况下，实现**+50个高难度验证器**，显著提升验证器体系的**复杂度**和**真实性**。

**关键优势**:
- ✅ 数据包扩展≤10%（仅需添加少量字段）
- ✅ 验证器实现效率高（模板化生成）
- ✅ 测试通过率高（基于现有数据）
- ✅ 实施周期短（20小时完成）

**预期结果**:
- 验证器总数达到 **220个**
- 复杂度提升至 **⭐⭐⭐⭐** 级别
- 真实场景覆盖达到 **95%**
- 为达成300验证器目标奠定坚实基础
