# frozen_string_literal: true

require_relative '../base_validator'

module V101V150
  class V140BookLuxuryCarAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v140_book_luxury_car_and_airport_dropoff_validator'
    self.task_id = 'a0b1c2d3-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    self.title = '帮张三订明天北京豪华轿车1天，并预订送机服务'
    self.description = '帮张三订明天北京豪华轿车1天，并预订送机服务'
    self.timeout_seconds = 300
    

    def task_description
      "帮张三订明天北京豪华轿车1天，并预订送机服务"
    end

    def prepare
      @location = "北京"
      @category = "豪华轿车"
      @pickup_date = Date.current + 1.day
      @rental_days = 1
      @return_date = @pickup_date + @rental_days.days
      @airport_name = "北京首都国际机场"

      # 预查询驾驶员信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @passenger.name
      @expected_driver_id = @passenger.id_number
      @expected_phone = @passenger.phone

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)

      raise "未找到符合条件的豪华轿车" if @available_cars.empty?
      
      # 查找北京机场位置
      @airport_loc = TransferLocation.find_by(
        city: @location,
        location_type: 'airport',
        data_version: 0
      )
      
      raise "未找到#{@location}机场位置" unless @airport_loc
      @airport = @airport_loc.name
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

      add_assertion "驾驶员信息正确（张三）", weight: 10 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "驾驶员姓名错误。期望: #{@expected_driver_name}, 实际: #{@car_order.driver_name}"
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "驾驶员身份证号错误。期望: #{@expected_driver_id}, 实际: #{@car_order.driver_id_number}"
      end

      add_assertion "创建了送机订单", weight: 20 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @transfer = all_transfers.first
        expect(@transfer).not_to be_nil, "未找到送机订单"
      end

      return if @transfer.nil?

      add_assertion "送机目的地=机场", weight: 5 do
        valid_airports = TransferLocation
          .where(city: @location, location_type: 'airport', data_version: 0)
          .pluck(:name)
        
        expect(valid_airports).to include(@transfer.location_to),
          "送机目的地不在TransferLocation机场中。实际: #{@transfer.location_to}"
      end

      add_assertion "送机乘客信息正确（张三）", weight: 5 do
        expect(@transfer.passenger_name).to eq(@expected_driver_name),
          "送机乘客姓名错误。期望: #{@expected_driver_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "送机乘客电话错误。期望: #{@expected_phone}, 实际: #{@transfer.passenger_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      car = @available_cars.first
      CarOrder.create!(
        user: user,
        car: car,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
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
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
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
        airport_name: @airport_name,
        airport: @airport,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @airport_name = data['airport_name']
      @airport = data['airport']
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_phone = data['expected_phone']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).order(price_per_day: :asc)
      
      @airport_loc = TransferLocation.find_by(
        city: @location,
        name: @airport,
        data_version: 0
      ) if @airport
    end
  end
end
