# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V133BookRegularTrainAndHotelValidator < BaseValidator
    self.validator_id = 'v133_book_regular_train_and_hotel_validator'
    self.task_id = 'c6d7e8f9-0a1b-2c3d-4e5f-6a7b8c9d0e1f'
    self.title = '预订普通列车+酒店1晚'
    self.description = '预订明天北京到天津的普通列车（C字头或Z字头，二等座），并预订天津酒店1晚'
    self.timeout_seconds = 300

    def task_description
      "预订明天北京到天津的普通列车（C字头或Z字头，二等座），并预订天津酒店1晚"
    end

    def prepare
      @departure_city = "北京"
      @arrival_city = "天津"
      @train_date = Date.current + 1.day
      @hotel_city = "天津"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day

      # 筛选C字头或Z字头列车
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'C%' OR train_number LIKE 'Z%'").order(price_second_class: :asc)

      raise "未找到符合条件的列车" if @available_trains.empty?

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)

      raise "未找到符合条件的酒店" if @available_hotels.empty?
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

      add_assertion "火车票路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@train_booking.train.departure_city).to eq(@departure_city)
        expect(@train_booking.train.arrival_city).to eq(@arrival_city)
      end

      add_assertion "车次为普通列车（C/Z字头）", weight: 15 do
        train_number = @train_booking.train.train_number
        is_regular = train_number.start_with?('C') || train_number.start_with?('Z')
        expect(is_regular).to be(true),
          "车次不是普通列车。期望: C/Z字头, 实际: #{train_number}"
      end

      add_assertion "座位类型=二等座", weight: 10 do
        expect(@train_booking.seat_type).to eq('second_class')
      end

      add_assertion "创建了酒店订单", weight: 20 do
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

      add_assertion "酒店城市正确（#{@hotel_city}）", weight: 15 do
        expect(@hotel_booking.hotel.city).to eq(@hotel_city)
      end

      add_assertion "入住日期=火车日期（#{@check_in_date}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date)
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
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
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
    end

    private

    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date.to_s,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'C%' OR train_number LIKE 'Z%'").order(price_second_class: :asc)

      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
