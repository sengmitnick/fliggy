# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V135BookEarliestTrainAndHotelPackageValidator < BaseValidator
    self.validator_id = 'v135_book_earliest_train_and_hotel_package_validator'
    self.task_id = 'b5c6d7e8-9f0a-1b2c-3d4e-5f6a7b8c9d0e'
    self.title = '预订最早高铁+酒店套餐（含早餐）'
    self.description = '预订明天上海到杭州的最早高铁（二等座），并预订上海酒店套餐1晚（含早餐）'
    self.timeout_seconds = 300

    def task_description
      "预订明天上海到杭州的最早高铁（二等座），并预订上海酒店套餐1晚（含早餐）"
    end

    def prepare
      @departure_city = "上海"
      @arrival_city = "杭州"
      @train_date = Date.today + 1.day
      @hotel_city = "上海"  # 酒店在上海，因为上海有 HotelPackage 数据
      @package_use_date = @train_date
      @min_departure_hour = 6
      @max_departure_hour = 8

      # 筛选最早车次（6:00-8:00）
      all_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'G%'").order('departure_time ASC')

      @available_trains = all_trains.select { |t| t.departure_time.hour >= @min_departure_hour && t.departure_time.hour < @max_departure_hour }

      raise "未找到符合条件的高铁" if @available_trains.empty?

      @available_packages = HotelPackage.where(
        city: @hotel_city,
        night_count: 1,
        data_version: 0
      ).order(price: :asc)

      raise "未找到符合条件的酒店套餐" if @available_packages.empty?
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

      add_assertion "火车票为最早车次", weight: 25 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= @min_departure_hour
        expect(departure_hour).to be < @max_departure_hour
      end

      add_assertion "座位类型=二等座", weight: 10 do
        expect(@train_booking.seat_type).to eq('second_class')
      end

      add_assertion "创建了酒店套餐订单", weight: 15 do
        all_package_orders = HotelPackageOrder
          .joins(:hotel_package)
          .includes(:hotel_package)
          .where(hotel_packages: { city: @hotel_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @package_order = all_package_orders.first
        expect(@package_order).not_to be_nil, "未找到酒店套餐订单"
      end

      return if @package_order.nil?

      add_assertion "酒店套餐城市正确（#{@hotel_city}）", weight: 15 do
        expect(@package_order.hotel_package.city).to eq(@hotel_city)
      end

      add_assertion "套餐晚数=1晚", weight: 10 do
        expect(@package_order.hotel_package.night_count).to eq(1)
      end

      add_assertion "使用日期=火车日期（#{@package_use_date}）", weight: 5 do
        expect(@package_order.check_in_date).to eq(@package_use_date)
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)

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

      package = @available_packages.first
      option = package.package_options.where(data_version: 0).order(:price).first
      HotelPackageOrder.create!(
        hotel_package_id: package.id,
        package_option_id: option.id,
        user_id: user.id,
        passenger_id: passenger.id,
        quantity: 1,
        total_price: option.price,
        booking_type: 'instant',
        status: 'pending',
        contact_name: user.name,
        contact_phone: '13800138000',
        check_in_date: @package_use_date,
        check_out_date: @package_use_date + 1.day,
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
        package_use_date: @package_use_date.to_s
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @package_use_date = Date.parse(data['package_use_date'])

      all_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).where("train_number LIKE 'G%'").order('departure_time ASC')

      @available_trains = all_trains.select { |t| t.departure_time.hour >= @min_departure_hour && t.departure_time.hour < @max_departure_hour }

      @available_packages = HotelPackage.where(
        city: @hotel_city,
        night_count: 1,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
