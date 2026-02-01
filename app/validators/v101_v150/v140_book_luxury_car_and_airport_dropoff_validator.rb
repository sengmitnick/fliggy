# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V140BookLuxuryCarAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v140_book_luxury_car_and_airport_dropoff_validator'
    self.task_id = 'a0b1c2d3-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    self.title = '预订豪华轿车+送机服务'
    self.description = '预订明天北京豪华轿车1天，并预订送机服务'

    def task_description
      "预订明天北京豪华轿车1天，并预订送机服务"
    end

    def prepare
      @location = "北京"
      @category = "豪华轿车"
      @pickup_date = Date.today + 1.day
      @rental_days = 1
      @return_date = @pickup_date + @rental_days.days
      @airport = "北京首都国际机场"

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的豪华轿车" if @available_cars.empty?
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

      add_assertion "车型类别=豪华轿车", weight: 15 do
        expect(@car_order.car.category).to eq(@category)
      end

      add_assertion "租车地点=北京", weight: 10 do
        expect(@car_order.car.location).to eq(@location)
      end

      add_assertion "租期=1天", weight: 10 do
        actual_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end

      add_assertion "创建了送机订单", weight: 25 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @transfer = all_transfers.first
        expect(@transfer).not_to be_nil, "未找到送机订单"
      end

      return if @transfer.nil?

      add_assertion "送机目的地=机场", weight: 15 do
        destination = @transfer.location_to.to_s
        has_airport = destination.include?("机场") || destination.include?("Airport") || destination.include?("北京")
        expect(has_airport).to be(true),
          "送机目的地不是机场。实际: #{destination}"
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
        pickup_datetime: @pickup_date.in_time_zone + 9.hours,
        return_datetime: (@pickup_date + @rental_days.days).in_time_zone + 20.hours,
        pickup_location: "北京市中心",
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
        data_version: @data_version
      )

      # 送机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "北京市中心",
        location_to: @airport,
        pickup_datetime: @pickup_date.in_time_zone + 14.hours,
        vehicle_type: 'luxury_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 120.0,
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
        airport: @airport
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @airport = data['airport']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
    end
  end
end
