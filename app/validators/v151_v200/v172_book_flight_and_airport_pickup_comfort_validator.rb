# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例172: 给李四预订后天广州到北京的航班，并预订首都机场接机到国贸CBD（航班11:50到达首都T3，舒适5座）
#
# 任务描述:
#   李四后天从广州坐飞机到北京，到达首都国际机场T3航站楼后需要接机送到国贸CBD，选择舒适5座车型。
#   需要创建2个订单：
#   1. 航班订单（后天广州→北京首都T3）
#   2. 接机订单（首都T3航站楼→国贸CBD，舒适5座，接机航班到达后30分钟）
#
# 业务流程:
#   1. 搜索并预订后天广州到北京的航班（到达首都国际机场T3航站楼）
#   2. 记录航班到达时间和到达机场位置
#   3. 选择"接我"服务（from_airport = 从机场接到目的地）
#   4. 上车点：首都国际机场T3航站楼（通过航班信息自动确定）
#   5. 下车点：国贸CBD（目的地）
#   6. 用车时间：航班到达时间后30分钟
#   7. 筛选舒适5座车型
#   8. 选择该车型中价格最低的套餐
#
# 复杂度分析:
#   1. 需要搜索并预订后天广州到北京的航班
#   2. 需要识别航班到达机场（首都T3航站楼）
#   3. 需要预订接机服务，起点必须匹配航班到达机场
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 需要筛选舒适5座车型
#   6. 需要选择该车型中价格最低的套餐
#   ❌ 不能一次性提供：需要先预订航班→获取到达信息→选择接机服务→上车点自动匹配→选择下车点→计算接送时间→筛选车型→对比价格→预订
#
# 评分标准（总分100分）:
#   1. 创建了航班订单（后天广州→北京首都T3） (15分)
#   2. 创建了接机订单 (15分)
#   3. 接机起点正确（首都国际机场T3航站楼） (15分)
#   4. 接机终点正确（国贸CBD） (15分)
#   5. 接送时间正确（航班到达后30分钟） (15分)
#   6. 车型正确（舒适5座） (10分)
#   7. 选择了该车型中价格最低的套餐 (10分)
#   8. 航班乘客信息正确（李四） (5分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v172_book_flight_and_airport_pickup_comfort_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V172BookFlightAndAirportPickupComfortValidator < BaseValidator
    self.validator_id = 'v172_book_flight_and_airport_pickup_comfort_validator'
    self.task_id = '3c8e7f2a-4d1b-9a6c-5e8f-7b3d2a1c4e5f'
    self.title = '给李四预订后天广州到北京的机票，并预订首都机场接机到国贸CBD（舒适5座）'
    self.description = '帮李四订后天从广州到北京的航班，到达首都机场T3后接机到国贸CBD，车子选舒适5座'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '广州'
      @arrival_city = '北京'
      @arrival_airport = '首都国际机场T3航站楼'  # 期望到达的机场
      @destination_location = '国贸CBD'  # 接机目的地
      @flight_date = Date.current + 2.days  # 后天出发
      @vehicle_category = 'comfort_5'  # 舒适5座
      @transfer_type = 'airport_pickup'
      @service_type = 'from_airport'
    
      # 预查询乘客信息（李四）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
      # 查找可用航班（到达首都T3的航班）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%首都%T3%")
    
      raise "未找到符合条件的航班" if @available_flights.empty?
    
      # 查找目标机场位置
      @airport_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_airport,
        location_type: 'airport',
        data_version: 0
      )
    
      expect(@airport_location).not_to be_nil, "数据包缺少机场位置: #{@arrival_airport}"
      return if @airport_location.nil?  # Guard clause
    
      # 查找目的地位置
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      expect(@destination).not_to be_nil, "数据包缺少目的地: #{@destination_location}"
      return if @destination.nil?  # Guard clause
    
      # 查找舒适5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      expect(@available_packages).not_to be_empty, "数据包缺少舒适5座套餐"
      return if @available_packages.empty?  # Guard clause
    
      @best_package = @available_packages.first
    
      expect(@available_flights).not_to be_empty, "数据包缺少后天#{@departure_city}→#{@arrival_city}的航班（到达首都T3）"
      return if @available_flights.empty?  # Guard clause
    
      # 获取示例航班的时间信息
      @example_flight = @available_flights.order(:departure_time).first
    
      {
        task: "请为李四预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班（到达首都国际机场T3航站楼），" \
              "并预订接机服务到#{@destination_location}（选择舒适5座车型）",
        scenario: "后天从#{@departure_city}坐飞机到#{@arrival_city}，到达首都T3后需要接机送到#{@destination_location}",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.to_s,
          arrival_airport: "首都国际机场T3航站楼",
          example_arrival_time: @example_flight.arrival_time.strftime('%H:%M'),
          example_pickup_time: (@example_flight.arrival_time + 30.minutes).strftime('%H:%M')
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "首都国际机场T3航站楼（上车点，通过#{@departure_city}→#{@arrival_city}航班到达信息自动确定）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_time_rule: "航班到达时间后30分钟",
        vehicle_category: '舒适5座（comfort_5）',
        flow_hint: "1. 搜索并预订#{@departure_city}→#{@arrival_city}航班（后天，到达首都T3，如#{@example_flight.arrival_time.strftime('%H:%M')}到达） → 2. 记录航班到达时间 → 3. 选择接机服务 → 4. 上车点自动=首都T3 → 5. 下车点输入#{@destination_location} → 6. 用车时间=航班到达后30分钟（#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}接机） → 7. 筛选舒适5座车型 → 8. 选择该车型价格最低的套餐",
        hint: "先预订航班（#{@example_flight.arrival_time.strftime('%H:%M')}到达首都T3），然后预订接机服务（接机时间=航班到达时间+30分钟=#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}），起点为首都国际机场T3航站楼，终点为#{@destination_location}，选择舒适5座车型中价格最低的套餐",
        statistics: {
          available_flights: @available_flights.count,
          available_packages: @available_packages.count,
          price_range: {
            min: @available_packages.minimum(:price),
            max: @available_packages.maximum(:price)
          }
        }
      }
    end
  
    def verify
      # 断言1: 创建了航班订单（后天广州→北京首都T3）(15%)
      add_assertion "创建了航班订单（后天#{@departure_city}→#{@arrival_city}首都T3）", weight: 15 do
        # 查找航班订单
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@flight_bookings).not_to be_empty, "未找到#{@departure_city}→#{@arrival_city}的航班订单"
        @flight_booking = @flight_bookings.first
      end
    
      return if @flight_booking.nil?  # Guard clause after assertion 1
    
      # 断言2: 创建了接机订单 (15%)
      add_assertion "创建了接机订单", weight: 15 do
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接机订单"
        @transfer = @transfers.first
      end
    
      return if @transfer.nil?  # Guard clause after assertion 2
    

    
      # 断言3: 接机起点正确（首都国际机场T3航站楼）(15%)
      add_assertion "接机起点正确（首都国际机场T3航站楼）", weight: 15 do
        # 验证上车点包含首都和T3
        expect(@transfer.location_from).to include('首都'),
          "接机起点错误（缺少首都）。期望包含: 首都国际机场T3航站楼, 实际: #{@transfer.location_from}"
        expect(@transfer.location_from).to include('T3'),
          "接机起点错误（缺少T3）。期望包含: 首都国际机场T3航站楼, 实际: #{@transfer.location_from}"
      end
    
      # 断言4: 接机终点正确（国贸CBD）(15%)
      add_assertion "接机终点正确（#{@destination_location}）", weight: 15 do
        # 验证下车点包含国贸CBD
        expect(@transfer.location_to).to include(@destination_location),
          "接机终点错误。期望包含: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      # 断言5: 接送时间正确（航班到达后30分钟）(15%)
      add_assertion "接送时间正确（航班到达后30分钟）", weight: 15 do
        flight = @flight_booking.flight
        expected_pickup_time = flight.arrival_time + 30.minutes
      
        # 允许±10分钟误差
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（航班到达#{flight.arrival_time.strftime('%H:%M')}后30分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}（相差#{(time_diff / 60).to_i}分钟）"
      end
    
      # 断言6: 车型正确（舒适5座）(10%)
      add_assertion "车型正确（舒适5座）", weight: 10 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车型选择错误。期望: #{@vehicle_category}（舒适5座），实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      # 断言7: 选择了该车型中价格最低的套餐 (10%)
      add_assertion "选择了该车型中价格最低的套餐", weight: 10 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
        cheapest = packages.min_by(&:price)
        actual_price = @transfer.transfer_package.price
        cheapest_price = cheapest.price
      
        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择该车型最便宜套餐。" \
          "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
          "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
      end
    
      # 断言8: 航班乘客信息正确（李四）(5%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 5 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
    
      # 步骤1: 预订航班（后天广州→北京首都T3）
      target_flight = @available_flights.order(:departure_time).first
      raise "未找到可用航班" unless target_flight
    
      flight_offer = target_flight.flight_offers.order(:price).first
      raise "航班没有可用套餐" unless flight_offer
    
      flight_booking = Booking.create!(
        user_id: user.id,
        flight_id: target_flight.id,
        flight_offer_id: flight_offer.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: flight_offer.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    
      # 步骤2: 预订接机（首都T3航站楼→国贸CBD，舒适5座，航班到达后30分钟）
      pickup_datetime = target_flight.arrival_time + 30.minutes
    
      # 查找舒适5座车型中价格最低的套餐
      target_package = @available_packages.order(:price).first
      raise "未找到舒适5座套餐" unless target_package
    
      Transfer.create!(
        user_id: user.id,
        transfer_package_id: target_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @arrival_airport,
        location_to: @destination_location,
        pickup_datetime: pickup_datetime,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: target_package.price,
        discount_amount: 0,
        status: 'pending',
        driver_status: 'pending',
        data_version: @data_version
      )
    end
  
    private
  
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        arrival_airport: @arrival_airport,
        destination_location: @destination_location,
        flight_date: @flight_date.to_s,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
  
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_airport = data['arrival_airport']
      @destination_location = data['destination_location']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%首都%T3%")
      
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
      
      @example_flight = @available_flights.order(:departure_time).first if @available_flights.present?
    end
  end
end
