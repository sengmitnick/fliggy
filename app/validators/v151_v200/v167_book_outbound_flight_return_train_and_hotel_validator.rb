# frozen_string_literal: true

require_relative '../base_validator'

# V167: 预订去程航班+返程火车+酒店
# 验证用户能够完成去程航班、返程火车、酒店住宿的组合下单

module V151V200
  class V167BookOutboundFlightReturnTrainAndHotelValidator < BaseValidator
    self.validator_id = 'v167_book_outbound_flight_return_train_and_hotel_validator'
    self.task_id = 'e7f8a9b0-1c2d-3e4f-5a6b-7c8d9e0f1a2b'
    self.title = '给张三预订明天去程航班+返程火车+北京→上海→北京酒店2晚'
    self.description = '预订明天北京到上海的航班，预订第4天上海回北京的火车，并预订上海酒店2晚'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.current + 1.day  # 明天
      @return_date = @outbound_date + 3.days
      @hotel_checkin_date = @outbound_date
      @hotel_checkout_date = @hotel_checkin_date + 2.days
      @nights = 2
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
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
      passenger = Passenger.find_by!(phone: @passenger.phone, data_version: 0)
      
      # 创建去程航班订单
      outbound_flight = @available_outbound_flights.first
      Booking.create!(
        user: user,
        flight: outbound_flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
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
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        total_price: return_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: @passenger.phone,
        payment_method: '花呗',
        total_price: room.price * @nights,
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        hotel_checkin_date: @hotel_checkin_date.to_s,
        hotel_checkout_date: @hotel_checkout_date.to_s,
        nights: @nights
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @nights = data['nights']
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
      add_assertion "酒店入住日期正确（航班当天）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言7: 乘客信息正确（张三）
      add_assertion "乘客信息正确（#{@expected_name}）", weight: 5 do
        expect(@outbound_booking.passenger_name).to eq(@expected_name),
          "乘客姓名错误。期望: #{@expected_name}, 实际: #{@outbound_booking.passenger_name}"
        expect(@outbound_booking.passenger_id_number).to eq(@expected_id_number),
          "乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@outbound_booking.passenger_id_number}"
      end
    end
  end
end
