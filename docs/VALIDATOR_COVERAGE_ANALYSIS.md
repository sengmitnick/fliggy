# 测试用例覆盖分析报告

## 📊 概述

本文档记录了项目中验证器（Validator）测试用例的覆盖情况，用于指导后续测试用例的开发。

**统计数据：**
- 已实现测试用例：46个
- 已覆盖核心模块：8个
- 未覆盖核心模块：18个
- 覆盖率：约 30% (8/26)

---

## ✅ 已覆盖的模块 (46个测试用例)

### 1. 酒店预订 (Hotels) - 7个用例
- **v001**: 预订后天入住一晚深圳的经济型酒店
- **v015**: 搜索北京评分最高的高档酒店（4星级及以上）
- **v017**: 预订明天上海任意酒店（入住1晚）
- **v018**: 预订后天北京高评分酒店（评分≥4.5）
- **v019**: 预订大后天广州便宜酒店（价格≤300元）
- **v020**: 预订明天深圳酒店（入住2晚）
- **v021**: 预订后天杭州商务酒店

### 2. 火车票 (Trains) - 11个用例
- **v002**: 预订后天北京到上海最早的高铁
- **v007**: 预订后天东京到京都的上午新干线车票（境外）
- **v011**: 搜索后天北京到天津最便宜的车票
- **v012**: 搜索明天欧洲境内最便宜的火车票（境外）
- **v022**: 预订明天北京到上海任意高铁
- **v023**: 预订后天上海到深圳的一等座
- **v024**: 预订明天杭州到北京最晚的高铁
- **v025**: 预订后天深圳到广州最快的高铁
- **v026**: 预订明天广州到上海最便宜的高铁（二等座）
- 其他相关用例

### 3. 航班 (Flights) - 10个用例
- **v003**: 预订深圳到北京后天的最低价机票
- **v010**: 搜索上海到深圳的最便宜航班（后天1人）
- **v027**: 预订明天上海到深圳任意航班
- **v028**: 预订后天北京到上海早班航班（12点前起飞）
- **v029**: 预订明天深圳到杭州最贵的航班
- **v030**: 预订后天广州到北京最早起飞的航班
- **v031**: 预订明天杭州到深圳经济舱航班
- 其他相关用例

### 4. 跟团游 (Tour Groups) - 8个用例
- **v004**: 预订价格合适的三亚5天4晚跟团游（2成人0儿童）
- **v009**: 搜索预算5000元以内的昆明旅游产品
- **v037**: 预订明天上海周边3天2晚跟团游
- **v038**: 预订明天北京4天3晚跟团游（2成人）
- **v039**: 预订后天三亚6天5晚便宜跟团游
- **v040**: 预订大后天广州5天4晚跟团游（1成人1儿童）
- **v041**: 预订明天杭州3天2晚精品小团（<10人）

### 5. 租车 (Cars) - 6个用例
- **v005**: 租赁后天北京的经济型轿车（3天）
- **v013**: 搜索成都适合家庭的7座SUV
- **v032**: 租赁明天上海任意车辆（1天）
- **v033**: 租赁后天北京SUV（2天）
- **v034**: 租赁明天深圳最便宜的车（预算≤100元/天）
- **v035**: 租赁后天广州豪华轿车（3天）
- **v036**: 租赁明天杭州商务车（2天，5座以上）

### 6. 汽车票 (Bus Tickets) - 6个用例
- **v006**: 预订后天上午的广州到深圳大巴票
- **v014**: 搜索后天杭州到深圳行程时间最短的班次
- **v042**: 预订大后天深圳到广州最便宜汽车票
- **v043**: 预订后天上海到杭州下午汽车票（12:00后）
- **v044**: 预订明天北京到天津最早汽车票
- **v045**: 预订明天广州到深圳任意汽车票
- **v046**: 预订后天杭州到上海晚上汽车票（18:00后）

### 7. 深度旅行 (Deep Travel) - 1个用例
- **v016**: 预订7天后的高评分深度旅行向导服务

### 8. 境外上网服务 (Internet Services - SIM卡) - 1个用例
- **v008**: 购买日本7天无限流量SIM卡

---

## ❌ 未覆盖的模块 (18个核心模块)

### 高优先级 (用户常用功能) - 5个

#### 1. 景点门票 (Attractions & Tickets)
- **控制器**: `attractions_controller`, `tickets_controller`, `ticket_orders_controller`
- **模型**: `Attraction`, `Ticket`, `TicketOrder`, `AttractionActivity`, `ActivityOrder`
- **功能**: 景点门票搜索、预订、活动预订
- **建议用例**: 
  - 预订热门景点门票（迪士尼、长城等）
  - 搜索城市景点并预订最便宜门票
  - 预订景点活动项目

#### 2. 酒店套餐 (Hotel Packages)
- **控制器**: `hotel_packages_controller`, `hotel_package_orders_controller`
- **模型**: `HotelPackage`, `HotelPackageOrder`, `PackageOption`
- **功能**: 酒店+景点/餐饮套餐预订
- **建议用例**:
  - 预订酒店+门票套餐
  - 搜索性价比最高的酒店套餐

#### 3. 签证服务 (Visas)
- **控制器**: `visas_controller`, `visa_orders_controller`, `visa_services_controller`
- **模型**: `VisaProduct`, `VisaOrder`, `VisaOrderTraveler`
- **功能**: 签证产品搜索、签证办理
- **建议用例**:
  - 办理日本旅游签证
  - 搜索最便宜的申根签证服务

#### 4. 保险服务 (Insurances)
- **控制器**: `insurances_controller`, `insurance_orders_controller`
- **模型**: `InsuranceProduct`, `InsuranceOrder`
- **功能**: 旅游保险搜索、购买
- **建议用例**:
  - 购买境外旅游保险
  - 购买国内短途旅游保险

#### 5. 接送机/专车 (Transfers)
- **控制器**: `transfers_controller`
- **模型**: `Transfer`, `TransferPackage`
- **功能**: 接送机、专车服务预订
- **建议用例**:
  - 预订机场接机服务
  - 预订火车站送站服务

---

### 中优先级 (特色服务) - 4个

#### 6. 邮轮 (Cruises)
- **控制器**: `cruises_controller`, `cruise_orders_controller`, `cruise_sailings_controller`
- **模型**: `Cruise`, `CruiseLine`, `CruiseShip`, `CruiseSailing`, `CruiseOrder`, `CruiseProduct`
- **功能**: 邮轮航线搜索、邮轮预订
- **建议用例**:
  - 预订日韩邮轮航线
  - 搜索性价比最高的地中海邮轮

#### 7. 包车游 (Chartered Tours)
- **控制器**: `chartered_tours_controller`, `charter_routes_controller`, `charter_bookings_controller`
- **模型**: `CharterRoute`, `CharterBooking`
- **功能**: 包车线路搜索、包车预订
- **建议用例**:
  - 预订三亚包车一日游
  - 搜索最便宜的包车线路

#### 8. 境外门票 (Abroad Tickets)
- **控制器**: `abroad_tickets_controller`, `abroad_ticket_orders_controller`
- **模型**: `AbroadTicket`, `AbroadTicketOrder`
- **功能**: 境外景点门票预订
- **建议用例**:
  - 预订迪士尼乐园门票
  - 预订环球影城门票

#### 9. 境外WiFi/流量套餐 (Internet Services - WiFi/Data)
- **控制器**: `internet_services_controller`
- **模型**: `InternetWifi`, `InternetDataPlan`
- **功能**: 境外WiFi设备租赁、流量套餐购买
- **建议用例**:
  - 租赁日本WiFi设备
  - 购买欧洲流量包

---

### 低优先级 (辅助功能) - 9个

#### 10. 定制游 (Custom Travel)
- **控制器**: `custom_travel_requests_controller`
- **模型**: `CustomTravelRequest`

#### 11. 民宿公寓 (Homestays)
- **控制器**: `homestays_controller`
- **模型**: 使用Hotel模型（type不同）

#### 12. 出境游 (Outbound Tours)
- **控制器**: `outbound_tours_controller`
- **模型**: 使用TourGroupProduct模型

#### 13. 自由行 (Free Travels)
- **控制器**: `free_travels_controller`
- **功能**: 组合产品

#### 14. 私家团 (Private Groups)
- **控制器**: `private_groups_controller`
- **模型**: 使用TourGroupProduct模型

#### 15. 会员系统 (Memberships)
- **控制器**: `members_controller`
- **模型**: `Membership`, `MembershipBenefit`, `BrandMembership`, `FamilyBenefit`

#### 16. 价格提醒 (Price Alerts)
- **控制器**: `price_alerts_controller`
- **模型**: `PriceAlert`

#### 17. 境外优惠券/购物 (Abroad Shopping)
- **控制器**: `abroad_shops_controller`, `abroad_coupons_controller`
- **模型**: `AbroadShop`, `AbroadBrand`, `AbroadCoupon`, `UserCoupon`

#### 18. 机酒套餐 (Flight Packages)
- **控制器**: `flight_packages_controller`
- **模型**: `FlightPackage`

---

## 📋 下一步计划

### Phase 1: 高优先级模块 (v047-v051)
1. **v047**: 预订景点门票
2. **v048**: 预订酒店套餐
3. **v049**: 办理签证服务
4. **v050**: 购买旅游保险
5. **v051**: 预订接送机服务

### Phase 2: 中优先级模块 (v052-v055)
1. **v052**: 预订邮轮航线
2. **v053**: 预订包车游
3. **v054**: 预订境外门票
4. **v055**: 租赁境外WiFi

### Phase 3: 低优先级模块 (根据需求补充)
- 定制游请求
- 民宿预订
- 价格提醒设置
- 会员权益使用

---

## 📝 用例设计原则

基于现有用例 v001-v046 的经验，新用例应遵循以下原则：

### 1. 复杂度控制
- **简单用例** (权重分布均匀): 适用于标准预订流程
- **中等用例** (核心项权重高): 包含筛选条件和对比逻辑
- **复杂用例** (多条件验证): 涉及多步骤操作和复杂计算

### 2. 评分标准 (100分制)
- 订单创建成功: 20-25分
- 基础信息正确: 30-40分（日期、地点、数量等）
- 核心业务逻辑: 30-40分（价格、评分、性价比等）
- 信息完整性: 10-20分（联系方式、支付信息等）

### 3. 必备元素
- `prepare()`: 准备测试数据，返回任务描述
- `verify()`: 验证订单是否符合要求
- `simulate()`: 模拟AI Agent操作（用于调试）
- `execution_state_data()`: 保存执行状态
- `restore_from_state()`: 恢复执行状态

### 4. 数据版本控制
- 所有查询必须带 `data_version: 0` 过滤基线数据
- 新创建的订单自动标记为 `data_version: 1`
- 确保测试数据隔离，不影响基线数据

---

## 📊 覆盖率目标

- **短期目标** (Q2 2025): 覆盖率提升至 50% (13/26 模块)
- **中期目标** (Q3 2025): 覆盖率提升至 75% (19/26 模块)
- **长期目标** (Q4 2025): 覆盖率达到 90%+ (23+/26 模块)

---

**文档版本**: v1.0  
**最后更新**: 2025-01-18  
**维护者**: AI Development Team
