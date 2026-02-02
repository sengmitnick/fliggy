# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例502: 预订航班+机场3公里内酒店
#
# 任务描述:
#   预订航班+机场3公里内酒店（便于转机）
#
# 评分标准:
#   - 创建了航班订单 (25%)
#   - 创建了酒店订单 (25%)
#   - 酒店在机场附近（≤3公里） (30%)
#   - 出发/到达城市正确 (10%)
#   - 日期合理 (10%)
module V151V200
  class V196BookFlightAndAirportVicinityHotelValidator < BaseValidator
    self.validator_id = 'v196_book_flight_and_airport_vicinity_hotel_validator'
    self.task_id = '98182723-1c20-486b-b2c2-ba4d2e48e1df'
    self.title = '预订航班+机场3公里内酒店'
    self.description = '预订航班+机场3公里内酒店（便于转机）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 2.days
      @max_distance = 3.0  # 公里
      
      # 查找航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的航班（#{@travel_date}）"
      
      # 查找机场附近酒店（通过features或hotel_type判断）
      @airport_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .select { |h| is_near_airport?(h) }
        .to_a
      
      if @airport_hotels.empty?
        # 如果没有明确标记的机场酒店，选择距离最近的
        @airport_hotels = Hotel
          .where(city: @arrival_city, data_version: 0)
          .select { |h| h.distance && h.distance <= @max_distance }
          .to_a
      end
      
      expect(@airport_hotels).not_to be_empty, 
        "数据包缺少#{@arrival_city}机场附近（≤#{@max_distance}公里）的酒店"
      
      {
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班，并预订机场#{@max_distance}公里内的酒店（便于转机）",
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
      
      # 断言3: 酒店在机场附近（≤3公里） (30%)
      add_assertion "酒店在机场附近（≤#{@max_distance}公里）", weight: 30 do
        hotel = @hotel_booking.hotel
        is_airport_hotel = is_near_airport?(hotel) || 
                          (hotel.distance && hotel.distance <= @max_distance)
        
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
      
      # 断言5: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择航班
      flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
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
      
      # 选择机场酒店
      airport_hotel = @airport_hotels.min_by(&:price)
      room = airport_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: airport_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: airport_hotel.price,
          original_price: airport_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: airport_hotel.id,
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
    
    def is_near_airport?(hotel)
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
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_distance = data['max_distance']
    end
  end
end
