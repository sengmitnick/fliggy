# frozen_string_literal: true

require_relative '../base_validator'

# V163: 预订往返航班+酒店住宿
# 验证用户能够完成往返航班预订+目的地酒店住宿的组合下单

module V101V150
  class V163BookRoundTripFlightAndHotelValidator < BaseValidator
    self.validator_id = 'v163_book_round_trip_flight_and_hotel_validator'
    self.task_id = 'a3b4c5d6-7e8f-9a0b-1c2d-3e4f5a6b7c8d'
    self.title = '预订往返航班并预订酒店住宿（北京⇄上海，3晚）'
    self.description = '预订后天北京到上海的往返航班（去程后天，返程第5天），并预订上海酒店3晚住宿'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.tomorrow + 1.day  # 后天出发
      @return_date = @outbound_date + 4.days  # 第5天返回
      @hotel_checkin_date = @outbound_date
      @hotel_checkout_date = @hotel_checkin_date + 3.days
      @nights = 3
      
      # 查找去程航班
      @available_outbound_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @outbound_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_outbound_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的航班"
      
      # 查找返程航班
      @available_return_flights = Flight
        .where(departure_city: @arrival_city, destination_city: @departure_city, flight_date: @return_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_return_flights).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程航班"
      
      # 查找酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建去程航班订单
      outbound_flight = @available_outbound_flights.first
      Booking.create!(
        user: user,
        flight: outbound_flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: outbound_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建返程航班订单
      return_flight = @available_return_flights.first
      Booking.create!(
        user: user,
        flight: return_flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: return_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          name: '标准双人间',
          size: 25.0,
          bed_type: 'double',
          price: 400.0,
          original_price: 500.0,
          amenities: ['免费WiFi', '空调', '热水'].to_json,
          breakfast_included: true,
          cancellation_policy: '免费取消',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price * @nights,
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了去程航班订单
      add_assertion "创建了去程航班订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @outbound_booking = all_bookings.first
        expect(@outbound_booking).not_to be_nil, "未找到去程航班订单"
      end
      
      return if @outbound_booking.nil?
      
      # 断言2: 创建了返程航班订单
      add_assertion "创建了返程航班订单（#{@arrival_city}→#{@departure_city}）", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @arrival_city, destination_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @return_booking = all_bookings.first
        expect(@return_booking).not_to be_nil, "未找到返程航班订单"
      end
      
      return if @return_booking.nil?
      
      # 断言3: 去程日期正确
      add_assertion "去程日期正确（#{@outbound_date}）", weight: 10 do
        expect(@outbound_booking.flight.flight_date).to eq(@outbound_date),
          "去程日期错误。期望: #{@outbound_date}（后天）, 实际: #{@outbound_booking.flight.flight_date}"
      end
      
      # 断言4: 返程日期正确
      add_assertion "返程日期正确（#{@return_date}）", weight: 10 do
        expect(@return_booking.flight.flight_date).to eq(@return_date),
          "返程日期错误。期望: #{@return_date}（第5天）, 实际: #{@return_booking.flight.flight_date}"
      end
      
      # 断言5: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 20 do
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
      
      # 断言6: 酒店入住日期和时长正确
      add_assertion "酒店入住日期和时长正确（3晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
        
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
    end
  end
end
