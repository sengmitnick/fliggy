# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例138: 帮张三订明天深圳机场接机服务（11:45从北京飞抵深圳到福田会展中心）+深圳租车（到达后14:00在深圳北站西广场租车中心取车，经济轿车租3天）
#
# 任务描述:
#   张三明天从北京飞深圳（11:45到达宝安国际机场T3航站楼），需要预订机场接机服务（明天中午11:45从机场到福田中心区会展中心接送服务点），到达市区后（约14:00）再在深圳北站西广场租车中心取经济轿车（租3天）。
#   Agent 需要创建2个订单（接机服务+租车订单），确保接机服务从机场到福田中心区会展中心接送服务点，租车地点在深圳北站西广场租车中心，取车时间在接机后（约14:00），车型为经济轿车，租期3天。
#
# 业务流程（9个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为接机乘客和驾驶员信息）
#   2. 明确航班出发地信息（从北京飞深圳，明天11:45到达）
#   3. 创建机场接机服务订单（transfer_type='airport_pickup', service_type='from_airport'）
#   4. 设置接机起点为宝安国际机场T3航站楼（location_from='宝安国际机场T3航站楼'）
#   5. 设置接机终点为福田中心区会展中心接送服务点（location_to='福田中心区会展中心接送服务点'）
#   6. 设置接机时间为明天中午11:45（pickup_datetime = 明天 11:45，对应CA1302航班到达时间）
#   7. 搜索深圳的租车服务，筛选车型类别=经济轿车，筛选取车地点在深圳北站西广场租车中心（非机场）
#   8. 按车辆价格升序排序，选择租车
#   9. 创建租车订单（pickup_location为市区租车点，pickup_datetime=明天14:00，return_datetime=明天+3天14:00，租期3天）
#
# 复杂度分析（10个关键点）：
#   1. 需要理解机场接机+市区租车的两模块组合预订场景
#   2. 需要理解接机服务类型（transfer_type='airport_pickup' 机场接机，service_type='from_airport' 从机场出发）
#   3. 需要理解航班出发地信息（从北京飞深圳，明确航班来源）
#   4. 需要设置接机起点为机场（location_from='深圳宝安国际机场'）
#   5. 需要明确接机时间（pickup_datetime = 明天 11:45，对应CA1302航班到达时间）
#   6. 需要协调租车取车时间：在接机到达市区后（约14:00），不能与接机同时
#   7. 需要区分租车地点：深圳北站西广场租车中心（非机场取车）
#   8. 需要选择经济轿车车型（category = '经济轿车'）
#   9. 需要计算租期3天（return_datetime = pickup_datetime + 3天）
#   10. 需要使用受益人信息作为接机乘客和驾驶员信息
#   ❌ 不能一次性提供所有信息：需要分别查询接机服务、租车数据，协调时间和地点逻辑，分步骤创建2个订单。
#
# 评分标准（11项，总计100分）：
#   1. 创建了接机订单（15分）
#   2. 接机地点=深圳机场（10分）
#   3. 接机目的地=福田会展中心服务点（10分）
#   4. 接机时间和乘客信息正确（时间=11:45，乘客=张三）（10分）
#   5. 创建了租车订单（15分）
#   6. 取车地点=深圳北站西广场租车中心（10分）
#   7. 取车时间在接机后（约14:00左右）（10分）
#   8. 车型类别=经济轿车（5分）
#   9. 租期3天（5分）
#   10. 还车时间=取车时间+3天（5分）
#   11. 驾驶员信息正确（张三的姓名、身份证号、联系电话）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v138_book_car_and_airport_pickup_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V138BookCarAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v138_book_car_and_airport_pickup_validator'
    self.task_id = 'e8f9a0b1-2c3d-4e5f-6a7b-8c9d0e1f2a3b'
    self.title = '帮张三订明天深圳机场接机服务（11:45从北京飞抵深圳到福田会展中心）+深圳租车（到达后14:00在深圳北站西广场租车中心取车，经济轿车租3天）'
    self.description = '帮张三订明天深圳机场接机服务（11:45从北京飞抵深圳到福田会展中心）+深圳租车（到达后14:00在深圳北站西广场租车中心取车，经济轿车租3天）'
    self.timeout_seconds = 300

    def task_description
      "帮张三订明天深圳机场接机服务（11:45从北京飞抵深圳到福田会展中心），并在到达后（14:00）在深圳北站西广场租车中心租经济轿车3天"
    end

    def prepare
      @location = "深圳"
      @category = "经济轿车"
      @pickup_date = Date.current + 1.day
      @rental_days = 3
      @return_date = @pickup_date + @rental_days.days

      # 预查询深圳机场接送点（TransferLocation - 宝安国际机场T3航站楼）
      @airport_loc = TransferLocation.find_by(
        city: @location,
        name: '宝安国际机场T3航站楼',
        location_type: 'airport',
        data_version: 0
      )

      raise "未找到深圳机场接送点: 宝安国际机场T3航站楼" unless @airport_loc

      # 预查询深圳市区接送点（TransferLocation - 福田中心区会展中心接送服务点）
      @city_loc = TransferLocation.find_by(
        city: @location,
        name: '福田中心区会展中心接送服务点',
        location_type: 'other',
        data_version: 0
      )

      raise "未找到深圳市区接送点: 福田中心区会展中心接送服务点" unless @city_loc

      # 预查询驾驶员信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_driver_name = @passenger.name
      @expected_driver_id = @passenger.id_number
      @expected_phone = @passenger.phone
      @expected_pickup_location = "深圳北站西广场租车中心"  # 明确的租车取车地点

      # 查询市区租车点的车辆（非机场）
      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).where.not("pickup_location LIKE ?", "%机场%").order(price_per_day: :asc)

      raise "未找到符合条件的市区经济轿车" if @available_cars.empty?
    end

    def verify
      # 断言1: 创建了接机订单 (15分) - 核心评分项
      add_assertion "创建了接机订单", weight: 15 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @transfer = all_transfers.first
        expect(@transfer).not_to be_nil, "未找到接机订单"
      end

      return if @transfer.nil?

      # 断言2: 接机地点=宝安国际机场T3航站楼（TransferLocation中location_type='airport'的地点） (10分)
      add_assertion "接机地点=宝安国际机场T3航站楼", weight: 10 do
        valid_locations = TransferLocation
          .where(city: '深圳', location_type: 'airport', data_version: 0)
          .pluck(:name)
        
        expect(valid_locations).to include(@transfer.location_from),
          "接机地点不在TransferLocation深圳机场中。实际: #{@transfer.location_from}, 可选: #{valid_locations.join(', ')}"
      end

      # 断言3: 接机目的地=福田中心区会展中心接送服务点（TransferLocation中location_type='other'的地点） (10分)
      add_assertion "接机目的地=福田中心区会展中心接送服务点", weight: 10 do
        valid_locations = TransferLocation
          .where(city: '深圳', location_type: 'other', data_version: 0)
          .pluck(:name)
        
        expect(valid_locations).to include(@transfer.location_to),
          "接机目的地不在TransferLocation深圳市区接送点中。实际: #{@transfer.location_to}, 可选: #{valid_locations.join(', ')}"
        
        # 确保不是机场
        airport_keywords = ['机场', 'Airport']
        is_airport = airport_keywords.any? { |keyword| @transfer.location_to.include?(keyword) }
        expect(is_airport).to be(false),
          "接机目的地不应该是机场。实际: #{@transfer.location_to}"
      end

      # 断言4: 接机时间和乘客信息正确（时间=11:45，乘客=张三） (10分)
      add_assertion "接机时间和乘客信息正确（时间=11:45，乘客=张三）", weight: 10 do
        # 验证接机时间=11:45
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
        expect(pickup_hour).to eq(11), "接机时间小时错误。期望: 11:45, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(45), "接机时间分钟错误。期望: 11:45, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        
        # 验证乘客信息=张三
        expect(@transfer.passenger_name).to eq(@expected_driver_name),
          "接机乘客姓名错误。期望: #{@expected_driver_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "接机乘客电话错误。期望: #{@expected_phone}, 实际: #{@transfer.passenger_phone}"
      end

      # 断言5: 创建了租车订单 (15分)
      add_assertion "创建了租车订单", weight: 15 do
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

      # 断言6: 取车地点=深圳北站西广场租车中心 (10分)
      add_assertion "取车地点=深圳北站西广场租车中心", weight: 10 do
        pickup_location = @car_order.pickup_location.to_s
        is_correct = pickup_location.include?("深圳北站西广场租车中心")
        expect(is_correct).to be(true),
          "取车地点应该是'深圳北站西广场租车中心'。实际: #{pickup_location}"
      end

      # 断言7: 取车时间在接机后（约14:00左右） (10分)
      add_assertion "取车时间在接机后（约14:00左右）", weight: 10 do
        pickup_hour = @car_order.pickup_datetime.hour
        # 验证取车时间在13:00-15:00之间（接机11:45，到达市区约13:00-14:00，取车约14:00）
        expect(pickup_hour).to be >= 13, "取车时间过早。期望: 13:00之后（接机后），实际: #{@car_order.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_hour).to be <= 15, "取车时间过晚。期望: 15:00之前，实际: #{@car_order.pickup_datetime.strftime('%H:%M')}"
      end

      # 断言8: 车型类别=经济轿车 (5分)
      add_assertion "车型类别=经济轿车", weight: 5 do
        expect(@car_order.car.category).to eq(@category)
      end

      # 断言9: 租期3天 (5分)
      add_assertion "租期3天", weight: 5 do
        pickup_date = @car_order.pickup_datetime.to_date
        return_date = @car_order.return_datetime.to_date
        actual_days = (return_date - pickup_date).to_i
        expect(actual_days).to eq(@rental_days),
          "租期错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end

      # 断言10: 还车时间=取车时间+3天 (5分)
      add_assertion "还车时间=取车时间+3天", weight: 5 do
        expected_return = @pickup_date + @rental_days.days
        expect(@car_order.return_datetime.to_date).to eq(expected_return)
      end

      # 断言11: 驾驶员信息正确（张三的姓名、身份证号、联系电话） (5分)
      add_assertion "驾驶员信息正确（张三）", weight: 5 do
        expect(@car_order.driver_name).to eq(@expected_driver_name),
          "驾驶员姓名错误。期望: #{@expected_driver_name}, 实际: #{@car_order.driver_name}"
        expect(@car_order.driver_id_number).to eq(@expected_driver_id),
          "驾驶员身份证号错误。期望: #{@expected_driver_id}, 实际: #{@car_order.driver_id_number}"
        expect(@car_order.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@car_order.contact_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      # 机场接机服务（从北京飞抵深圳，11:45到达CA1302）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_loc.name,  # 使用TransferLocation查询结果（宝安国际机场T3航站楼）
        location_to: @city_loc.name,  # 使用TransferLocation查询结果（福田中心区会展中心接送服务点）
        pickup_datetime: @pickup_date.in_time_zone + 11.hours + 45.minutes,  # 11:45接机（CA1302到达时间）
        vehicle_type: 'economy_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 80.0,
        status: 'pending',
        data_version: @data_version
      )

      # 市区租车（接机后约2小时，14:00取车）
      car = @available_cars.first
      
      CarOrder.create!(
        user: user,
        car: car,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        pickup_datetime: @pickup_date.in_time_zone + 14.hours,  # 14:00取车（接机11:45，到达市区约13:00-14:00）
        return_datetime: (@pickup_date + @rental_days.days).in_time_zone + 14.hours,  # 3天后14:00还车
        pickup_location: car.pickup_location,
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
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
        airport_location_name: @airport_loc&.name,
        city_destination_name: @city_loc&.name,
        expected_driver_name: @expected_driver_name,
        expected_driver_id: @expected_driver_id,
        expected_phone: @expected_phone,
        expected_pickup_location: @expected_pickup_location
      }
    end

    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @pickup_date = Date.parse(data['pickup_date'])
      @rental_days = data['rental_days']
      @return_date = Date.parse(data['return_date'])
      @expected_driver_name = data['expected_driver_name']
      @expected_driver_id = data['expected_driver_id']
      @expected_phone = data['expected_phone']
      @expected_pickup_location = data['expected_pickup_location']

      # 重新查询TransferLocation
      @airport_loc = TransferLocation.find_by(
        city: @location,
        name: data['airport_location_name'],
        location_type: 'airport',
        data_version: 0
      ) if data['airport_location_name']

      @city_loc = TransferLocation.find_by(
        city: @location,
        name: data['city_destination_name'],
        location_type: 'other',
        data_version: 0
      ) if data['city_destination_name']

      @available_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).where.not("pickup_location LIKE ?", "%机场%").order(price_per_day: :asc)

      @passenger = Passenger.find_by(name: @expected_driver_name, data_version: 0)
    end
  end
end
