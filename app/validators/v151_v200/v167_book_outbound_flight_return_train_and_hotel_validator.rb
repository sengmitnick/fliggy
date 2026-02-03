# frozen_string_literal: true

require_relative '../base_validator'

# V167: 预订去程航班+返程火车+酒店
# 验证用户能够完成去程航班、返程火车、酒店住宿的组合下单

module V151V200
  class V167BookOutboundFlightReturnTrainAndHotelValidator < BaseValidator
    self.validator_id = 'v167_book_outbound_flight_return_train_and_hotel_validator'
    self.task_id = 'e7f8a9b0-1c2d-3e4f-5a6b-7c8d9e0f1a2b'
    self.title = '预订去程航班+返程火车+酒店（北京→上海→北京，2晚）'
    self.description = '预订明天北京到上海的航班，预订第4天上海回北京的火车，并预订上海酒店2晚'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.tomorrow
      @return_date = @outbound_date + 3.days
      @hotel_checkin_date = @outbound_date
      @hotel_checkout_date = @hotel_checkin_date + 2.days
      @nights = 2
      
      # 查找去程航班
      @available_outbound_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @outbound_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_outbound_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的航班"
      
      # 查找返程火车
      @available_return_trains = Train
        .where(departure_city: @arrival_city, arrival_city: @departure_city, data_version: 0)
        .by_date(@return_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_return_trains).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程火车"
      
      # 查找酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
      
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
      
      # 创建返程火车订单
      return_train = @available_return_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: return_train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: return_train.price_second_class,
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
        @outbound_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@outbound_booking).not_to be_nil, "未找到去程航班订单"
      end
      
      return if @outbound_booking.nil?
      
      # 断言2: 创建了返程火车订单
      add_assertion "创建了返程火车订单（#{@arrival_city}→#{@departure_city}）", weight: 20 do
        @return_ticket = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @arrival_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@return_ticket).not_to be_nil, "未找到返程火车订单"
      end
      
      return if @return_ticket.nil?
      
      # 断言3: 去程是航班
      add_assertion "去程是航班", weight: 15 do
        expect(@outbound_booking.flight).not_to be_nil, "去程应该是航班"
      end
      
      # 断言4: 返程是火车
      add_assertion "返程是火车", weight: 15 do
        expect(@return_ticket.train).not_to be_nil, "返程应该是火车"
      end
      
      # 断言5: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 15 do
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
      
      # 断言6: 酒店入住日期正确
      add_assertion "酒店入住日期正确（航班当天）", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      end
    end
  end
end
