# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例188: 给张三预订商务舱+五星酒店
#
# 任务描述:
#   高端商务出行，预订商务舱+五星酒店
#
# 评分标准:
#   - 创建了航班订单和酒店订单 (25%)
#   - 航班舱位正确（商务舱） (15%)
#   - 酒店星级正确（五星级） (15%)
#   - 航班城市正确（北京→上海） (15%)
#   - 酒店城市正确（上海） (15%)
#   - 入住日期合理（航班到达当天或次日） (15%)
module V151V200
  class V188BookLuxuryFlightAndFiveStarHotelValidator < BaseValidator
    self.validator_id = 'v188_book_luxury_flight_and_five_star_hotel_validator'
    self.task_id = 'cb093340-9f54-4e5d-bcd0-fe9ac36bde61'
    self.title = '给张三预订商务舱+五星酒店'
    self.description = '预订商务舱+五星酒店'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @required_seat_class = 'business'
      @required_star_level = 5
      
      # 查找商务舱航班
      @available_business_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, seat_class: @required_seat_class, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_business_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的商务舱航班（#{@travel_date}）"
      
      # 查找五星级酒店（star_level >= 5）
      @available_five_star_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where('star_level >= ?', @required_star_level)
        .to_a
      
      expect(@available_five_star_hotels).not_to be_empty,
        "数据包缺少#{@arrival_city}的五星级酒店"
      
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
      # 断言1: 创建了航班订单和酒店订单 (20%)
      add_assertion "创建了航班订单和酒店订单", weight: 20 do
        all_flight_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @flight_booking = all_flight_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到航班订单（#{@departure_city}→#{@arrival_city}）"
        
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @flight_booking.nil? || @hotel_booking.nil?
      
      # 断言2: 航班舱位正确（商务舱） (13%)
      add_assertion "航班舱位正确（商务舱）", weight: 13 do
        flight = @flight_booking.flight
        expect(flight.seat_class).to eq('business'),
          "舱位错误。期望: business（商务舱）, 实际: #{flight.seat_class}"
      end
      
      # 断言3: 酒店星级正确（五星级，即>=5星） (13%)
      add_assertion "酒店星级正确（五星级）", weight: 13 do
        hotel = @hotel_booking.hotel
        expect(hotel.star_level).to be >= 5,
          "酒店星级错误。期望: 至少5星, 实际: #{hotel.star_level}星"
      end
      
      # 断言4: 航班城市正确（北京→上海） (13%)
      add_assertion "航班城市正确（#{@departure_city}→#{@arrival_city}）", weight: 13 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{flight.destination_city}"
      end
      
      # 断言5: 酒店城市正确（上海） (13%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 13 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言6: 入住日期合理（航班到达当天或次日） (10%)
      add_assertion "入住日期合理（航班到达当天或次日）", weight: 10 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        
        is_reasonable = (checkin_date == arrival_date || checkin_date == arrival_date + 1.day)
        expect(is_reasonable).to be(true),
          "入住日期不合理。航班到达: #{arrival_date}, 酒店入住: #{checkin_date}（应为到达当天或次日）"
      end
      
      # 断言7: 航班乘客信息正确 (3%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 3 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
      end
      
      # 断言8: 航班联系电话正确 (7%)
      add_assertion "航班联系电话正确（#{@expected_phone}）", weight: 7 do
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
      
      # 断言9: 酒店入住人信息正确 (5%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言10: 航班出发日期正确 (3%)
      add_assertion "航班出发日期正确（#{@travel_date}）", weight: 3 do
        actual_date = @flight_booking.flight.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}, 实际: #{actual_date}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 创建航班订单（商务舱）
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
      
      # 创建酒店订单（五星级）
      hotel = @available_five_star_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
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
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '陈静'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @required_seat_class = data['required_seat_class']
      @required_star_level = data['required_star_level']
      
      # 重建 available 数据
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