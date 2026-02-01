# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V138BookCarAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v138_book_car_and_airport_pickup_validator'
    self.task_id = 'e8f9a0b1-2c3d-4e5f-6a7b-8c9d0e1f2a3b'
    self.title = '预订租车+机场接机服务'
    self.description = '预订明天深圳机场自取的经济轿车3天，并预订机场接机服务'

    def task_description
      "预订明天深圳机场自取的经济轿车3天，并预订机场接机服务"
    end

    def prepare
      @location = "深圳"
      @category = "经济轿车"
      @pickup_date = Date.today + 1.day
      @rental_days = 3
      @return_date = @pickup_date + @rental_days.days
      @pickup_location = "深圳宝安国际机场"

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的经济轿车" if @available_cars.empty?
    end

    def verify
      add_assertion "创建了租车订单", weight: 25 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { location: @location, category: @category })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @car_order = all_car_orders.first
        expect(@car_order).not_to be_nil, "未找到租车订单"
      end

      return if @car_order.nil?

      add_assertion "租车地点正确（#{@location}）", weight: 15 do
        expect(@car_order.car.location).to eq(@location)
      end

      add_assertion "车型类别=经济轿车", weight: 10 do
        expect(@car_order.car.category).to eq(@category)
      end

      add_assertion "取车时间=明天", weight: 10 do
        expect(@car_order.pickup_datetime.to_date).to eq(@pickup_date)
      end

      add_assertion "还车时间=3天后", weight: 10 do
        expected_return = @pickup_date + @rental_days.days
        expect(@car_order.return_datetime.to_date).to eq(expected_return)
      end

      add_assertion "创建了接机订单", weight: 20 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @transfer = all_transfers.first
        expect(@transfer).not_to be_nil, "未找到接机订单"
      end

      return if @transfer.nil?

      add_assertion "接机地点=深圳机场", weight: 10 do
        location = @transfer.location_from.to_s
        has_airport = location.include?("机场") || location.include?("Airport") || location.include?("深圳")
        expect(has_airport).to be(true),
          "接机地点不是深圳机场。实际: #{location}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)

      car = @available_cars.first
      
      CarOrder.create!(
        user: user,
        car: car,
        driver_name: user.name,
        driver_id_number: '110101199001011234',
        contact_phone: '13800138000',
        pickup_datetime: @pickup_date.in_time_zone + 10.hours,
        return_datetime: (@pickup_date + @rental_days.days).in_time_zone + 18.hours,
        pickup_location: @pickup_location,
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
        data_version: @data_version
      )

      # 机场接机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @pickup_location,
        location_to: "深圳市区",
        pickup_datetime: @pickup_date.in_time_zone + 9.hours,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 80.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        location: @location,
        category: @category,
        pickup_date: @pickup_date.to_s,
        rental_days: @rental_days,
        return_date: @return_date.to_s,
        pickup_location: @pickup_location
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @pickup_location = data['pickup_location']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
    end
  end
end
