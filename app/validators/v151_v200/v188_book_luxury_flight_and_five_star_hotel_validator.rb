# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例188: 预订商务舱+五星酒店
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
    self.title = '预订商务舱+五星酒店'
    self.description = '高端商务出行，预订商务舱+五星酒店'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 1.day
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
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的商务舱航班，并预订#{@arrival_city}的五星级酒店（高端商务出行）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        seat_class: '商务舱',
        hotel_requirement: '五星级',
        hint: "系统中有#{@available_business_flights.size}个商务舱航班和#{@available_five_star_hotels.size}家五星酒店可选"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单和酒店订单 (25%)
      add_assertion "创建了航班订单和酒店订单", weight: 25 do
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
      
      # 断言2: 航班舱位正确（商务舱） (15%)
      add_assertion "航班舱位正确（商务舱）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.seat_class).to eq('business'),
          "舱位错误。期望: business（商务舱）, 实际: #{flight.seat_class}"
      end
      
      # 断言3: 酒店星级正确（五星级，即>=5星） (15%)
      add_assertion "酒店星级正确（五星级）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.star_level).to be >= 5,
          "酒店星级错误。期望: 至少5星, 实际: #{hotel.star_level}星"
      end
      
      # 断言4: 航班城市正确（北京→上海） (15%)
      add_assertion "航班城市正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{flight.destination_city}"
      end
      
      # 断言5: 酒店城市正确（上海） (15%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言6: 入住日期合理（航班到达当天或次日） (15%)
      add_assertion "入住日期合理（航班到达当天或次日）", weight: 15 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        
        is_reasonable = (checkin_date == arrival_date || checkin_date == arrival_date + 1.day)
        expect(is_reasonable).to be(true),
          "入住日期不合理。航班到达: #{arrival_date}, 酒店入住: #{checkin_date}（应为到达当天或次日）"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建航班订单（商务舱）
      flight = @available_business_flights.first
      Booking.create!(
        user: user,
        flight_id: flight.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单（五星级）
      hotel = @available_five_star_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          room_type: '豪华双人间',
          bed_type: 'king',
          price: 800.0,
          original_price: 1000.0,
          area: 45.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'deluxe',
          data_version: 0
        )
      end
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
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
        required_star_level: @required_star_level
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @required_seat_class = data['required_seat_class']
      @required_star_level = data['required_star_level']
    end
  end
end
