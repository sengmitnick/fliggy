# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例107: 预订定制游（上海经典路线，8小时包车，7座商务车）
#
# 核心验证点:
# 1. 订单创建: 定制游订单创建成功
# 2. 城市/路线: 上海经典路线（category='classic'）
# 3. 包车时长: 8小时
# 4. 车辆类型: 7座商务车
# 5. 出发日期: 明天
# 6. 价格计算: 总价符合车型和时长计算逻辑
module V101V150
  class V107CharteredTourBookingValidator < BaseValidator
    self.validator_id = 'v107_chartered_tour_booking_validator'
    self.task_id = 'e9d3f5a7-2c8b-4e1f-a6d9-8b4c1f7e3a52'
    self.title = '预订定制游（上海经典路线，8小时包车）'
    self.description = '预订上海定制游，选择经典路线，预订8小时包车服务，选择7座商务车，4位乘客，明天出发'
    self.timeout_seconds = 240
  
    def prepare
      # 准备阶段：查询可用的定制游路线
      @city_name = '上海'
      @route_category = 'classic'  # 经典路线
      @duration_hours = 8           # 8小时包车
      @vehicle_seats = 7            # 7座商务车
      @passengers_count = 4         # 4位乘客
      @departure_date = Date.tomorrow  # 明天出发
    
      # 查询可用的定制游路线（上海+经典路线）
      @available_routes = CharterRoute
        .joins(:city)
        .where(cities: { name: @city_name }, data_version: @data_version)
        .where(category: @route_category)
    
      {
        task: "请在定制游页面（/chartered_tours）预订#{@city_name}的定制包车游，选择#{@route_category == 'classic' ? '经典' : '热门'}路线，包车时长#{@duration_hours}小时，选择#{@vehicle_seats}座商务车，#{@passengers_count}位乘客，出发日期为明天（#{@departure_date.strftime('%Y-%m-%d')}）",
        city_name: @city_name,
        route_category: @route_category == 'classic' ? '经典路线' : '热门路线',
        duration_hours: @duration_hours,
        vehicle_seats: @vehicle_seats,
        passengers_count: @passengers_count,
        departure_date: @departure_date.strftime('%Y-%m-%d'),
        hint: "访问 /chartered_tours，筛选城市为'上海'、category='classic'的路线，选择一条路线后，选择8小时包车服务，车辆类型seats=7，填写出发日期为明天",
        available_routes_count: @available_routes.count
      }
    end
  
    def verify
      # 断言1: 订单已创建 (权重30%)
      add_assertion "订单已创建", weight: 30 do
        all_bookings = CharterBooking
          .joins(charter_route: :city)
          .where(cities: { name: @city_name }, data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_bookings).not_to be_empty, "未找到任何定制游订单"
        @booking = all_bookings.first
      end
    
      return if @booking.nil?
    
      # 断言2: 路线正确（上海经典路线）(权重20%)
      add_assertion "路线正确（上海经典路线）", weight: 20 do
        expect(@booking.charter_route.city.name).to eq(@city_name),
          "城市不符合要求。期望: #{@city_name}, 实际: #{@booking.charter_route.city.name}"
        expect(@booking.charter_route.category).to eq(@route_category),
          "路线类别不符合要求。期望: #{@route_category}（经典路线），实际: #{@booking.charter_route.category}"
      end
    
      # 断言3: 包车时长正确（8小时）(权重15%)
      add_assertion "包车时长正确（8小时）", weight: 15 do
        expect(@booking.duration_hours).to eq(@duration_hours),
          "包车时长错误。期望: #{@duration_hours}小时, 实际: #{@booking.duration_hours}小时"
      end
    
      # 断言4: 车辆类型正确（7座商务车）(权重15%)
      add_assertion "车辆类型正确（7座商务车）", weight: 15 do
        expect(@booking.vehicle_type.seats).to eq(@vehicle_seats),
          "车辆座位数错误。期望: #{@vehicle_seats}座, 实际: #{@booking.vehicle_type.seats}座"
      end
    
      # 断言5: 出发日期正确（明天）(权重10%)
      add_assertion "出发日期正确（明天）", weight: 10 do
        expect(@booking.departure_date).to eq(@departure_date),
          "出发日期错误。期望: #{@departure_date}（明天）, 实际: #{@booking.departure_date}"
      end
    
      # 断言6: 订单总价合理 (权重10%)
      add_assertion "订单总价合理", weight: 10 do
        base_price = @booking.vehicle_type.price_for_duration(@duration_hours)
        expect(@booking.total_price).to be > 0,
          "订单总价为0，应该根据车型和时长计算"
        expect(@booking.total_price).to be >= base_price * 0.9,
          "订单总价过低。基础价格: #{base_price}, 实际: #{@booking.total_price}"
      end
    end
  
    def execution_state_data
      { 
        city_name: @city_name,
        route_category: @route_category,
        duration_hours: @duration_hours,
        vehicle_seats: @vehicle_seats,
        passengers_count: @passengers_count,
        departure_date: @departure_date.to_s
      }
    end
  
    def restore_from_state(data)
      @city_name = data['city_name']
      @route_category = data['route_category']
      @duration_hours = data['duration_hours']
      @vehicle_seats = data['vehicle_seats']
      @passengers_count = data['passengers_count']
      @departure_date = Date.parse(data['departure_date'])
      @available_routes = CharterRoute
        .joins(:city)
        .where(cities: { name: @city_name }, data_version: @data_version)
        .where(category: @route_category)
    end
  
    def simulate
      # Step 1: 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # Step 2: 查找城市（上海）
      city = City.where(data_version: 0).find_by(name: @city_name)
      raise "未找到城市: #{@city_name}" unless city
    
      # Step 3: 查找符合条件的定制游路线（上海+经典路线）
      route = CharterRoute.where(
        data_version: 0,
        city_id: city.id,
        category: @route_category
      ).first
      raise "未找到符合条件的定制游路线" unless route
    
      # Step 4: 查找车辆类型（7座商务车）
      vehicle_type = VehicleType.where(data_version: 0, seats: @vehicle_seats).first
      raise "未找到#{@vehicle_seats}座车辆类型" unless vehicle_type
    
      # Step 5: 计算总价（基础价格 + 周末加价）
      base_price = vehicle_type.price_for_duration(@duration_hours)
      # Weekend markup: 周末加价20%
      total_price = @departure_date.saturday? || @departure_date.sunday? ? (base_price * 1.2).round(2) : base_price
    
      # Step 6: 创建定制游订单
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: @departure_date,
        departure_time: '09:00',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        passengers_count: @passengers_count,
        contact_name: '周八',
        contact_phone: '13800138011',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
