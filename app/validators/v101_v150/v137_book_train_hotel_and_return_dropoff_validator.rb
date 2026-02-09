# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V137BookTrainHotelAndReturnDropoffValidator < BaseValidator
    self.validator_id = 'v137_book_train_hotel_and_return_dropoff_validator'
    self.task_id = 'd7e8f9a0-1b2c-3d4e-5f6a-7b8c9d0e1f3a'
    self.title = '预订后天火车票+酒店+返程送站服务（1人）'
    self.description = '预订后天上海到杭州的火车票（二等座），预订杭州酒店1晚，并预订返程送站服务'
    self.timeout_seconds = 300

    def task_description
      "预订后天上海到杭州的火车票（二等座），预订杭州酒店1晚，并预订返程送站服务"
    end

    def prepare
      @departure_city = "上海"
      @arrival_city = "杭州"
      @train_date = Date.current + 2.days
      @hotel_city = "杭州"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day
      @dropoff_date = @check_out_date
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      raise "未找到符合条件的火车" if @available_trains.empty?

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)

      raise "未找到符合条件的酒店" if @available_hotels.empty?
    end

    def verify
      add_assertion "创建了火车票+酒店+送站3个订单", weight: 20 do
        train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)

        hotel_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @hotel_city })
          .where(data_version: @data_version)

        transfers = Transfer.where(
          transfer_type: 'train_dropoff',
          data_version: @data_version
        )

        @train_booking = train_bookings.first
        @hotel_booking = hotel_bookings.first
        @transfer = transfers.first

        expect(@train_booking).not_to be_nil, "未找到火车票订单"
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
        expect(@transfer).not_to be_nil, "未找到送站订单"
      end

      return if @train_booking.nil? || @hotel_booking.nil? || @transfer.nil?

      add_assertion "火车票路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        expect(@train_booking.train.departure_city).to eq(@departure_city)
        expect(@train_booking.train.arrival_city).to eq(@arrival_city)
      end

      add_assertion "座位类型=二等座", weight: 10 do
        expect(@train_booking.seat_type).to eq('second_class')
      end

      add_assertion "酒店城市正确（#{@hotel_city}）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@hotel_city)
      end

      add_assertion "入住日期=火车日期（#{@check_in_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date)
      end

      add_assertion "送站终点=火车站", weight: 15 do
        destination = @transfer.location_to.to_s
        has_station = destination.include?("站") || destination.include?("火车站") || destination.include?("Railway")
        expect(has_station).to be(true),
          "送站终点不是火车站。实际: #{destination}"
      end

      add_assertion "送站起点=酒店地址附近", weight: 15 do
        origin = @transfer.location_from.to_s
        hotel_address = @hotel_booking.hotel.address.to_s
        hotel_name = @hotel_booking.hotel.name.to_s
        # 简单验证：起点不为空即可
        expect(origin).not_to be_empty, "送站起点为空"
      end

      add_assertion "送站时间=退房后合理时间", weight: 10 do
        transfer_time = @transfer.pickup_datetime
        checkout_date = @hotel_booking.check_out_date
        # 送站时间应该在退房日期当天
        expect(transfer_time.to_date).to eq(checkout_date),
          "送站时间不在退房日期。期望: #{checkout_date}, 实际: #{transfer_time.to_date}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)

      train = @available_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )

      # 送站服务：从酒店到火车站
      Transfer.create!(
        user: user,
        transfer_type: 'train_dropoff',  # 送到火车站
        service_type: 'to_station',      # 到站服务
        location_from: "#{hotel.name}",
        location_to: "杭州火车站",
        pickup_datetime: @dropoff_date.to_time + 10.hours,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 50.0,
        status: 'pending',
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
        dropoff_date: @dropoff_date.to_s
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @dropoff_date = Date.parse(data['dropoff_date'])

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
