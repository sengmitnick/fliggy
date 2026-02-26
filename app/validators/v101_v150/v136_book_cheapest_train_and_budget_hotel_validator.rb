# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V136BookCheapestTrainAndBudgetHotelValidator < BaseValidator
    self.validator_id = 'v136_book_cheapest_train_and_budget_hotel_validator'
    self.task_id = 'c6d7e8f9-0a1b-2c3d-4e5f-6a7b8c9d0e2f'
    self.title = '帮张三订后天北京到天津的火车票（二等座），同时订天津经济型酒店1晚，要求火车票+酒店总价最低'
    self.description = '帮张三订后天北京到天津的火车票（二等座），同时订天津经济型酒店1晚，要求火车票+酒店总价最低'
    self.timeout_seconds = 300

    def task_description
      "帮张三订后天北京到天津的火车票（二等座），同时订天津经济型酒店1晚，要求火车票+酒店总价最低"
    end

    def prepare
      @departure_city = "北京"
      @arrival_city = "天津"
      @train_date = Date.current + 2.days
      @hotel_city = "天津"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day
      @max_hotel_price = 300.0
      @max_train_price = 60.0

      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      raise "未找到符合条件的火车" if @available_trains.empty?

      # 经济型酒店（≤300元）
      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).where('price <= ?', @max_hotel_price).order(price: :asc)

      raise "未找到符合条件的经济型酒店" if @available_hotels.empty?

      # 计算最低总价
      cheapest_train = @available_trains.first
      cheapest_hotel = @available_hotels.first
      cheapest_room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      @min_total_price = cheapest_train.price_second_class + (cheapest_room ? cheapest_room.price : cheapest_hotel.price)
    end

    def verify
      add_assertion "创建了火车票订单", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车票订单"
      end

      return if @train_booking.nil?

      add_assertion "火车票为最低价（≤#{@max_train_price}元）", weight: 15 do
        train_price = @train_booking.train.price_second_class
        expect(train_price).to be <= @max_train_price
      end

      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
      end

      add_assertion "创建了酒店订单", weight: 10 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @hotel_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end

      return if @hotel_booking.nil?

      add_assertion "酒店为经济型（price≤#{@max_hotel_price}元）", weight: 15 do
        hotel_price = @hotel_booking.hotel.price
        expect(hotel_price).to be <= @max_hotel_price
      end

      add_assertion "酒店城市正确（#{@hotel_city}）", weight: 5 do
        expect(@hotel_booking.hotel.city).to eq(@hotel_city)
      end

      add_assertion "总价优化（火车+酒店总价最低）", weight: 15 do
        train_price = @train_booking.train.price_second_class
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        expect(total_price).to be <= @min_total_price * 1.15
      end

      add_assertion "入住日期=火车日期（#{@check_in_date}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date)
      end

      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      train = @available_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
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
        train_date: @train_date.to_s,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_hotel_price: @max_hotel_price,
        max_train_price: @max_train_price,
        min_total_price: @min_total_price,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_hotel_price = data['max_hotel_price'].to_f
      @max_train_price = data['max_train_price'].to_f
      @min_total_price = data['min_total_price'].to_f
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).where('price <= ?', @max_hotel_price).order(price: :asc)
    end
  end
end
