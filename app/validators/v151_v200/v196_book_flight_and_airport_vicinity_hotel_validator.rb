# frozen_string_literal: true

require_relative '../base_validator'

# V196: 给王芳预订明天北京到上海的航班+机场3公里内酒店（住一晚）
#
# 任务描述:
#   用户需要为王芳预订出行服务，包含：
#   1) 航班订单（Booking，北京到上海，明天出发）
#   2) 机场附近酒店（HotelBooking，上海机场≤3公里范围，住一晚，便于转机）
#   3) 乘客和入住人（王芳）
#   确保航班出发/到达城市、酒店距离机场范围、住宿天数、乘客信息、入住日期与航班衔接正确
#
# 评分标准:
#   - 创建了航班订单（北京→上海） (25%)
#   - 创建了酒店订单（上海） (25%)
#   - 酒店在机场附近（≤3公里） (15%)
#   - 出发/到达城市正确（北京→上海） (10%)
#   - 乘客和入住人信息正确（王芳） (15%)
#   - 日期合理（入住日期为航班到达日或次日） (10%)
module V151V200
  class V196BookFlightAndAirportVicinityHotelValidator < BaseValidator
    self.validator_id = 'v196_book_flight_and_airport_vicinity_hotel_validator'
    self.task_id = '98182723-1c20-486b-b2c2-ba4d2e48e1df'
    self.title = '给王芳预订明天北京到上海的航班+机场3公里内酒店（住一晚）'
    self.description = '给王芳预订明天北京到上海的航班+机场3公里内酒店（住一晚）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @max_distance = 3.0  # 公里
      
      # 查找航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的航班（#{@travel_date}）"
      
      # 查找机场附近酒店（优先使用distance字段）
      @airport_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .select { |h| is_near_airport?(h) }
        .to_a
      
      expect(@airport_hotels).not_to be_empty, 
        "数据包缺少#{@arrival_city}机场附近（≤#{@max_distance}公里）的酒店"
      
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班，并预订机场#{@max_distance}公里内的酒店（住一晚，便于转机）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        max_distance: @max_distance,
        hint: "选择机场附近的酒店，方便转机或早班飞机"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (25%)
      add_assertion "创建了航班订单", weight: 25 do
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 创建了酒店订单 (25%)
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 酒店在机场附近（≤3公里） (15%)
      add_assertion "酒店在机场附近（≤#{@max_distance}公里）", weight: 15 do
        hotel = @hotel_booking.hotel
        is_airport_hotel = is_near_airport?(hotel)
        
        expect(is_airport_hotel).to be(true),
          "酒店不在机场附近。酒店: #{hotel.name}（距离#{hotel.distance}公里），要求: ≤#{@max_distance}公里"
      end
      
      # 断言4: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确", weight: 10 do
        flight = @flight_booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言5: 乘客和入住人信息正确（周敏） (15%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 15 do
        # 检查航班乘客姓名
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        
        # 检查航班联系人
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系人电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言6: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 选择航班
      flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: flight.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 选择机场酒店
      airport_hotel = @airport_hotels.min_by(&:price)
      room = airport_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: airport_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    def is_near_airport?(hotel)
      # 优先使用distance字段（更可靠）
      if hotel.distance.present?
        distance_km = hotel.distance.is_a?(String) ? hotel.distance.to_f : hotel.distance
        return distance_km <= @max_distance
      end
      
      # 备用: 基于文本匹配
      return true if hotel.hotel_type&.include?('机场')
      return true if hotel.name&.include?('机场')
      return true if hotel.address&.include?('机场')
      return true if hotel.features&.include?('机场')
      false
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_distance: @max_distance
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_distance = data['max_distance']
    end
  end
end
