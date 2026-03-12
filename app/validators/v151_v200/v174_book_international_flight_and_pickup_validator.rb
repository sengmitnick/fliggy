# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例174: 给刘强预订3天后从东京到达上海浦东T2的国际航班，并预订深夜接机到陆家嘴金融区（航班22:00到达浦东T2，经济5座最便宜套餐）
#
# 任务描述:
#   刘强预订3天后从东京到达上海浦东国际机场T2航站楼的国际航班（深夜22:00到达），需要接机到陆家嘴金融区。
#   需要创建2个订单：
#   1. 航班订单（东京→上海浦东T2，22:00到达）
#   2. 接机订单（浦东T2 → 陆家嘴金融区，经济5座，接机时间22:30）
#
# 业务流程:
#   1. 搜索并预订3天后从东京到达上海浦东T2的国际航班（22:00到达）
#   2. 记录航班到达时间和到达机场位置（浦东T2，不是T1）
#   3. 选择"接我"服务（from_airport = 从机场接到目的地）
#   4. 上车点：浦东国际机场T2航站楼（通过航班信息自动确定）
#   5. 下车点：陆家嘴金融区
#   6. 用车时间：航班到达后30分钟（22:30接机）
#   7. 车型选择：经济5座（economy_5）
#   8. 选择该车型中价格最低的套餐
#
# 复杂度分析:
#   1. 需要搜索并预订从东京到达上海浦东T2的国际航班（22:00到达）
#   2. 需要识别航班到达机场（浦东T2，不同于T1）
#   3. 深夜接机服务（22:30接机）
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 需要根据航班到达位置自动填充上车点（浦东T2航站楼）
#   6. 从多个经济5座套餐中选择最便宜的
#
# 验证分数: 100分
#   - 创建了航班订单（3天后从东京到达上海浦东T2，22:00到达）: 15分
#   - 创建了接机订单: 15分
#   - 航班到达机场正确（浦东T2，不是T1）: 15分
#   - 接机起点正确（浦东T2，不是T1）: 15分
#   - 接机终点正确（陆家嘴金融区）: 10分
#   - 接送时间正确（深夜22:30，航班到达后30分钟）: 15分
#   - 车型正确（经济5座）: 10分
#   - 选择了该车型中价格最低的套餐: 5分
#
# 相关文件:
#   - app/models/booking.rb
#   - app/models/transfer.rb
#   - app/models/flight.rb
#   - app/models/transfer_package.rb
#   - app/models/transfer_location.rb

module V151V200
  class V174BookInternationalFlightAndPickupValidator < BaseValidator
    self.validator_id = 'v174_book_international_flight_and_pickup_validator'
    self.task_id = '6c54e97f-e56a-441b-adcb-a0be3cb045e2'
    self.title = '给刘强预订3天后从东京到达上海浦东T2的国际航班，并预订深夜接机到陆家嘴（航班22:00到达浦东T2，经济5座最便宜套餐）'
    self.description = '帮刘强订3天后从东京到达上海浦东机场T2的国际航班（深夜22点到达），然后接机到陆家嘴金融区'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '东京'
      @arrival_city = '上海'
      @arrival_airport = '浦东国际机场T2航站楼'
      @destination_location = '陆家嘴金融区'
      @flight_date = Date.current + 3.days  # 3天后到达
      @arrival_hour = 22  # 深夜到达
      @vehicle_category = 'economy_5'
      @transfer_type = 'airport_pickup'
      @service_type = 'from_airport'
    
      # 预查询乘客信息（刘强）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
      # 查找可用航班（东京→上海浦东T2，深夜22:00到达）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%浦东%T2%")
       .select { |f| f.arrival_time.hour == @arrival_hour }
    
      expect(@available_flights).not_to be_empty, "数据包缺少3天后从#{@departure_city}到达#{@arrival_city}浦东T2的航班（22:00到达）"
      return if @available_flights.empty?  # Guard clause
    
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
    
      # 查找经济5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      expect(@available_packages).not_to be_empty, "数据包缺少经济5座套餐"
      return if @available_packages.empty?  # Guard clause
    
      @best_package = @available_packages.first
    
      # 获取示例航班的时间信息
      @example_flight = @available_flights.find { |f| f.arrival_time.hour == 22 && f.arrival_time.min == 0 } || @available_flights.first
    
      {
        task: "请为刘强预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到达#{@arrival_city}浦东国际机场T2航站楼的国际航班（深夜22:00到达），" \
              "并预订接机服务到#{@destination_location}（经济5座）",
        scenario: "3天后从#{@departure_city}坐国际航班到达上海浦东T2（深夜22:00），刘强需要接机送到#{@destination_location}",
        passenger: @expected_passenger_name,
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_airport: "浦东国际机场T2航站楼（注意是T2不是T1）",
          flight_date: @flight_date.to_s,
          example_arrival_time: @example_flight.arrival_time.strftime('%H:%M'),
          example_pickup_time: (@example_flight.arrival_time + 30.minutes).strftime('%H:%M')
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "浦东国际机场T2航站楼（上车点，通过航班到达信息自动确定，注意是T2不是T1）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_time_rule: "航班到达时间后30分钟",
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 搜索并预订从#{@departure_city}到达上海浦东T2的国际航班（3天后，22:00到达） → 2. 记录航班到达时间 → 3. 选择接机服务 → 4. 上车点自动=浦东国际机场T2航站楼 → 5. 下车点输入#{@destination_location} → 6. 用车时间=航班到达后30分钟（#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}接机） → 7. 筛选经济5座车型 → 8. 选择该车型价格最低的套餐",
        hint: "注意到达航站楼是T2（不是T1）。深夜接机，接机时间应为航班到达后30分钟（约#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}），必须选择经济5座中价格最低的套餐",
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
      # 断言1: 创建了航班订单（3天后从东京到达上海浦东T2，22:00到达）(15%)
      add_assertion "创建了航班订单（3天后从#{@departure_city}到达#{@arrival_city}浦东T2，22:00到达）", weight: 15 do
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { 
            departure_city: @departure_city,
            destination_city: @arrival_city 
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@flight_bookings).not_to be_empty, "未找到从#{@departure_city}到达#{@arrival_city}的航班订单"
        @flight_booking = @flight_bookings.first
        
        # 验证到达时间是22:00
        arrival_time = @flight_booking.flight.arrival_time
        expect(arrival_time.hour).to eq(22), 
          "航班到达时间错误。期望22:00到达，实际#{arrival_time.strftime('%H:%M')}到达"
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
    
      # 断言3: 航班到达机场正确（浦东T2，不是T1）(15%)
      add_assertion "航班到达机场正确（浦东T2，不是T1）", weight: 15 do
        flight = @flight_booking.flight
        arrival_airport = flight.arrival_airport
        is_valid = arrival_airport.include?('浦东') && arrival_airport.include?('T2')
        
        expect(is_valid).to be_truthy,
          "航班到达机场错误。期望: 浦东T2（或浦东国际机场T2航站楼）, 实际: #{arrival_airport}"
      end
    
      # 断言4: 接机起点正确（浦东T2，不是T1）(15%)
      add_assertion "接机起点正确（浦东T2，不是T1）", weight: 15 do
        location_from = @transfer.location_from
        is_valid = location_from.include?('浦东') && location_from.include?('T2')
        
        expect(is_valid).to be_truthy,
          "接机起点错误。期望: #{@arrival_airport}（浦东T2或浦东国际机场T2航站楼，不是T1），实际: #{location_from}"
      end
    
      # 断言5: 接机终点正确（陆家嘴金融区）(10%)
      add_assertion "接机终点正确（#{@destination_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接机终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      # 断言6: 接送时间正确（深夜22:30，航班到达后30分钟）(15%)
      add_assertion "接送时间正确（深夜，航班到达后30分钟）", weight: 15 do
        flight = @flight_booking.flight
        expected_pickup_time = flight.arrival_time + 30.minutes
      
        # 允许±10分钟误差
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（航班到达#{flight.arrival_time.strftime('%H:%M')}后30分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}（相差#{(time_diff / 60).to_i}分钟）"
      end
    
      # 断言7: 车型正确（经济5座）(10%)
      add_assertion "车型正确（经济5座）", weight: 10 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车型选择错误。期望: #{@vehicle_category}（经济5座），实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      # 断言8: 选择了该车型中价格最低的套餐 (5%)
      add_assertion "选择了该车型中价格最低的套餐", weight: 5 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
        cheapest = packages.min_by(&:price)
        actual_price = @transfer.transfer_package.price
        cheapest_price = cheapest.price
      
        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择该车型最便宜套餐。" \
          "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
          "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
    
      # 步骤1: 预订国际航班（3天后从东京到达上海浦东T2，深夜22:00到达）
      target_flight = @available_flights.find { |f| f.arrival_time.hour == 22 && f.arrival_time.min == 0 } || @available_flights.first
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
    
      # 步骤2: 预订接机服务（浦东T2 → 陆家嘴金融区，经济5座，接机时间=航班到达后30分钟）
      pickup_datetime = target_flight.arrival_time + 30.minutes
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @airport_location.name,
        location_to: @destination.name,
        pickup_datetime: pickup_datetime,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        passenger_count: 1,
        luggage_count: 2,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    
      { flight_booking: flight_booking, transfer: transfer }
    end
  
    private
  
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        arrival_airport: @arrival_airport,
        destination_location: @destination_location,
        flight_date: @flight_date.to_s,
        arrival_hour: @arrival_hour,
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
      @flight_date = Date.parse(data['flight_date'])
      @arrival_hour = data['arrival_hour']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
    
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
    
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%浦东%T2%")
       .select { |f| f.arrival_time.hour == @arrival_hour }
    
      @airport_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_airport,
        location_type: 'airport',
        data_version: 0
      )
    
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      @best_package = @available_packages.first
    end
  end
end
