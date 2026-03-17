# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例200: 给王芳预订明天上海5星度假酒店+经典一日游包车（8小时）
#
# 任务描述:
#   帮王芳订明天上海的5星度假型酒店，并预订上海经典一日游包车服务（8小时）
#
# 核心要求:
#   - 酒店类型：5星度假型酒店
#   - 包车路线：上海经典一日游（包含司机导游服务）
#   - 包车时长：8小时
#   - 时间安排：明天入住酒店，包车游览时间在入住期间
#   - 联系人：王芳（统一联系人信息）
#
# 业务流程:
#   1. 查找上海的5星度假型酒店
#   2. 查找"上海经典一日游"包车路线（CharterRoute）
#   3. 选择合适的车型（VehicleType，座位数满足需求）
#   4. 创建酒店订单（入住明天，退房后天）
#   5. 创建包车游订单（游览时间在入住期间，包含司机导游服务，时长8小时）
#
# 复杂度分析:
#   - 数据查询：酒店、包车路线、车型（3个模型）
#   - 业务逻辑：酒店订单 + 包车游订单（2个订单）
#   - 类型过滤：5星度假型酒店、整晚房、合适车型
#   - 时间关联：包车时间与酒店入住时间协调
#
# 评分标准（总分100分）：
#   1. 创建了酒店订单（30分）
#   2. 创建了包车游订单（30分）
#   3. 酒店星级正确（5星）（15分）
#   4. 包车路线正确（上海经典一日游）（10分）
#   5. 包车时长正确（8小时）（5分）
#   6. 联系人信息正确（王芳）（5分）
#   7. 包车时间合理（游览期间在入住期间内）（5分）
module V151V200
  class V200BookScenicResortAndCharterTourValidator < BaseValidator
    self.validator_id = 'v200_book_scenic_resort_and_charter_tour_validator'
    self.task_id = '1c8e72f9-d895-4e13-9e5d-912749a6b8c5'
    self.title = '给王芳预订明天上海5星度假酒店+经典一日游包车（8小时）'
    self.description = '帮王芳订明天上海的5星度假型酒店+上海经典一日游包车服务（8小时）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = '上海'
      @route_keyword = '经典'  # 上海经典一日游
      @check_in_date = Date.current + 1.day  # 明天
      @passengers_count = 1
      @star_level = 5  # 5星酒店
      @duration_hours = 8  # 包车时长8小时
      
      # 查找5星度假型酒店
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .where(star_level: @star_level)
        .order(price: :desc)
        .to_a
      
      expect(@available_hotels).not_to be_empty,
        "数据包缺少#{@city}的#{@star_level}星酒店"
      
      # 查找上海经典一日游路线
      @available_routes = CharterRoute
        .joins(:city)
        .where(cities: { name: @city }, data_version: 0)
        .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
        .to_a
      
      expect(@available_routes).not_to be_empty,
        "数据包缺少#{@city}的包车游路线（#{@route_keyword}）"
      
      # 查找合适的车型
      @available_vehicles = VehicleType
        .where(data_version: 0)
        .where('seats >= ?', @passengers_count)
        .order(:seats)
        .to_a
      
      expect(@available_vehicles).not_to be_empty,
        "数据包缺少包车车型"
      
      {
        task: "请为#{@passenger.name}预订#{@check_in_date.strftime('%m月%d日')}#{@city}的#{@star_level}星度假型酒店，并预订#{@city}#{@route_keyword}一日游包车服务（#{@duration_hours}小时）",
        city: @city,
        star_level: @star_level,
        route_keyword: @route_keyword,
        duration_hours: @duration_hours,
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        passengers_count: @passengers_count,
        hint: "选择#{@star_level}星度假型酒店，预订#{@city}#{@route_keyword}一日游包车（#{@duration_hours}小时，包含司机导游）"
      }
    end
    
    def verify
      # 断言1: 创建了酒店订单 (30%)
      add_assertion "创建了酒店订单", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@city}）"
      end
      
      # 断言2: 创建了包车游订单 (30%)
      add_assertion "创建了包车游订单", weight: 30 do
        @charter_booking = CharterBooking
          .joins(:charter_route)
          .includes(:charter_route)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@charter_booking).not_to be_nil, "未找到包车游订单"
      end
      
      return if @hotel_booking.nil? || @charter_booking.nil?
      
      # 断言3: 酒店星级正确（5星） (15%)
      add_assertion "酒店星级正确（#{@star_level}星）", weight: 15 do
        hotel = @hotel_booking.hotel
        
        expect(hotel.star_level).to eq(@star_level),
          "酒店星级不匹配。期望: #{@star_level}星, 实际: #{hotel.star_level}星，酒店: #{hotel.name}"
      end
      
      # 断言4: 包车路线正确（上海经典一日游） (10%)
      add_assertion "包车路线正确（#{@city}#{@route_keyword}一日游）", weight: 10 do
        route = @charter_booking.charter_route
        expect(route).not_to be_nil, "包车游订单没有关联路线"
        
        expect(route.city.name).to eq(@city),
          "包车路线城市不匹配。期望: #{@city}, 实际: #{route.city.name}"
        
        expect(route.name).to include(@route_keyword),
          "包车路线不匹配。期望包含: #{@route_keyword}, 实际: #{route.name}"
      end
      
      # 断言5: 包车时长正确（8小时） (5%)
      add_assertion "包车时长正确（#{@duration_hours}小时）", weight: 5 do
        expect(@charter_booking.duration_hours).to eq(@duration_hours),
          "包车时长不匹配。期望: #{@duration_hours}小时, 实际: #{@charter_booking.duration_hours}小时"
      end
      
      # 断言6: 联系人信息正确（王芳） (5%)
      add_assertion "联系人信息正确（#{@expected_passenger_name}）", weight: 5 do
        # 检查包车游订单联系人
        expect(@charter_booking.contact_name).to eq(@expected_passenger_name),
          "包车游订单联系人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@charter_booking.contact_name}"
        
        expect(@charter_booking.contact_phone).to eq(@expected_phone),
          "包车游订单联系人电话错误。期望: #{@expected_phone}, 实际: #{@charter_booking.contact_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言7: 包车时间合理（游览期间在入住期间内） (5%)
      add_assertion "包车时间合理（游览期间在入住期间内）", weight: 5 do
        checkin_date = @hotel_booking.check_in_date
        checkout_date = @hotel_booking.check_out_date
        charter_date = @charter_booking.departure_date
        
        # 包车日期应在入住期间
        expect(charter_date).to be >= checkin_date,
          "包车日期早于入住日期。入住: #{checkin_date}, 包车: #{charter_date}"
        expect(charter_date).to be < checkout_date,
          "包车日期不在入住期间。入住: #{checkin_date}~#{checkout_date}, 包车: #{charter_date}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 创建酒店订单（选择5星酒店）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤room_category='overnight'，排除钟点房
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_in_date + 2.days,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price * 2,
        data_version: @data_version
      )
      
      # 创建包车游订单（选择上海经典一日游路线，时长8小时）
      route = @available_routes.first
      vehicle = @available_vehicles.first
      
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle.id,
        departure_date: @check_in_date,
        departure_time: '09:00',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        contact_name: passenger.name,
        contact_phone: passenger.phone,
        passengers_count: @passengers_count,
        pickup_address: hotel.address || "#{@city}市中心",
        total_price: vehicle.hourly_price_8h || (vehicle.hourly_price * 8),
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        star_level: @star_level,
        route_keyword: @route_keyword,
        duration_hours: @duration_hours,
        check_in_date: @check_in_date&.to_s,
        passengers_count: @passengers_count
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = data['city']
      @star_level = data['star_level']
      @route_keyword = data['route_keyword']
      @duration_hours = data['duration_hours']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @passengers_count = data['passengers_count']
    end
  end
end
