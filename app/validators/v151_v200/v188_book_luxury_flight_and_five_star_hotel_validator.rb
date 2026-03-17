# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例188: 给陈静预订明天北京到上海的商务舱航班+上海五星级酒店
#
# 任务描述:
#   陈静需要明天从北京出差到上海，要求预订商务舱航班和五星级酒店。
#   这是典型的高端商务出行场景，Agent需要搜索并预订商务舱航班，
#   然后预订上海的五星级酒店（星级>=5星），并确保入住日期与航班到达日期匹配。
#
# 业务流程（5个关键步骤）：
#   1. 搜索北京→上海的航班（明天出发，商务舱）
#   2. 筛选商务舱航班（seat_class = 'business'）
#   3. 预订商务舱航班（乘客陈静）
#   4. 搜索上海的酒店（位置必须在上海，星级>=5星）
#   5. 预订五星级酒店（凌晨到达可提前一天入住，其他航班当天或次日入住，退房日期=入住+1天）
#
# 复杂度分析（5个关键点）：
#   1. 需要筛选商务舱航班（区分经济舱/商务舱/头等舱）
#   2. 需要筛选五星级酒店（star_level >= 5）
#   3. 需要理解城市匹配逻辑：航班到达城市（上海）= 酒店城市（上海）
#   4. 需要计算合理的入住日期：航班到达当天或次日入住
#   5. 需要确保航班和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索商务舱航班→预订航班→理解到达城市→搜索上海五星酒店→计算入住日期→预订酒店
#
# 评分标准（7项，总计100分）：
#   - 创建了航班订单和酒店订单（双订单）（25分）
#   - 航班舱位正确（商务舱，business）（20分）
#   - 酒店星级正确（五星级，star_level >= 5）（20分）
#   - 航班出发日期正确（明天）（10分）
#   - 入住日期合理（凌晨航班可提前一天入住，其他航班当天/次日入住）（15分）
#   - 航班乘客信息正确（陈静，含姓名+电话）（5分）
#   - 酒店入住人信息正确（陈静，含姓名+电话）（5分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v188_book_luxury_flight_and_five_star_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V188BookLuxuryFlightAndFiveStarHotelValidator < BaseValidator
    self.validator_id = 'v188_book_luxury_flight_and_five_star_hotel_validator'
    self.task_id = 'cb093340-9f54-4e5d-bcd0-fe9ac36bde61'
    self.title = '给陈静预订明天北京到上海的商务舱航班+上海五星级酒店'
    self.description = '帮陈静订明天从北京到上海的商务舱航班，并预订上海的五星级酒店（高端商务出行）'
    self.timeout_seconds = 300
    
    def prepare
      # Step 1: 加载用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # Step 2: 设置查询条件
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @required_seat_class = 'business'
      @required_star_level = 5
      
      # Step 3: 查找商务舱航班（北京→上海，明天）
      @available_business_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, seat_class: @required_seat_class, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_business_flights).not_to be_empty,
        "数据包缺失：未找到#{@departure_city}→#{@arrival_city}的商务舱航班（#{@travel_date}）"
      
      # Step 4: 查找五星级酒店（上海，star_level >= 5）
      @available_five_star_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where('star_level >= ?', @required_star_level)
        .to_a
      
      expect(@available_five_star_hotels).not_to be_empty,
        "数据包缺失：未找到#{@arrival_city}的五星级酒店"
      
      # Step 5: 返回任务信息
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的商务舱航班，并预订#{@arrival_city}的五星级酒店（高端商务出行）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        seat_class: '商务舱',
        hotel_requirement: '五星级',
        hint: "系统中有#{@available_business_flights.size}个商务舱航班和#{@available_five_star_hotels.size}家五星酒店可选"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单和酒店订单（双订单存在性验证）
      add_assertion "创建了航班订单和酒店订单", weight: 25 do
        # 查询航班订单（按城市对筛选，不限制舱位）
        all_flight_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @flight_booking = all_flight_bookings.first
        expect(@flight_booking).not_to be_nil, 
          "未找到航班订单（#{@departure_city}→#{@arrival_city}）"
        
        # 查询酒店订单（按城市筛选，不限制星级）
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, 
          "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @flight_booking.nil? || @hotel_booking.nil?
      
      # 断言2: 航班舱位正确（商务舱）
      add_assertion "航班舱位正确（商务舱）", weight: 20 do
        flight = @flight_booking.flight
        expect(flight.seat_class).to eq('business'),
          "舱位错误 - 期望: business（商务舱）, 实际: #{flight.seat_class}（#{flight.seat_class == 'economy' ? '经济舱' : flight.seat_class == 'first' ? '头等舱' : flight.seat_class}）"
      end
      
      # 断言3: 酒店星级正确（五星级，即star_level >= 5）
      add_assertion "酒店星级正确（五星级）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.star_level).to be >= 5,
          "酒店星级不符 - 期望: 至少5星（五星级）, 实际: #{hotel.star_level}星"
      end
      
      # 断言4: 航班出发日期正确（明天）
      add_assertion "航班出发日期正确（#{@travel_date}）", weight: 10 do
        actual_date = @flight_booking.flight.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误 - 期望: #{@travel_date}（明天）, 实际: #{actual_date}"
      end
      
      # 断言5: 酒店入住日期正确（航班起飞当天）
      add_assertion "酒店入住日期正确（航班起飞当天）", weight: 15 do
        flight_date = @flight_booking.flight.flight_date
        checkin_date = @hotel_booking.check_in_date
        
        # 酒店入住日期=航班起飞当天（即使凌晨到达，也办理起飞日的入住）
        expect(checkin_date).to eq(flight_date),
          "入住日期错误 - 航班起飞: #{flight_date}, 酒店入住: #{checkin_date}（应为起飞当天，即使凌晨到达也办理起飞日入住）"
      end
      
      # 断言6: 航班乘客信息正确（姓名+电话）
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 5 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误 - 期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误 - 期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
      
      # 断言7: 酒店入住人信息正确（姓名+电话）
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误 - 期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误 - 期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    def simulate
      # Step 1: 加载用户和乘客
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Step 2: 创建航班订单（商务舱）
      flight = @available_business_flights.first
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
      
      # Step 3: 创建酒店订单（五星级，入住日期=航班到达日）
      hotel = @available_five_star_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,  # 到达当天入住
        check_out_date: arrival_date + 1.day,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        required_seat_class: @required_seat_class,
        required_star_level: @required_star_level,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      # Step 1: 恢复用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '陈静'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      # Step 2: 恢复查询条件
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @required_seat_class = data['required_seat_class']
      @required_star_level = data['required_star_level']
      
      # Step 3: 重建可用航班和酒店数据
      @available_business_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, seat_class: @required_seat_class, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      @available_five_star_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where('star_level >= ?', @required_star_level)
        .to_a
    end
  end
end
