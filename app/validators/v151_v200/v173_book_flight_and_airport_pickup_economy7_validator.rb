# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例173: 给王芳等6人预订3天后成都到杭州的航班，并预订萧山机场接机到西湖（王芳、刘强、小明、小红、陈静、吴勇，航班11:50到达萧山，经济7座最便宜套餐）
#
# 任务描述:
#   王芳等6人3天后从成都坐飞机到杭州，到达萧山国际机场后需要接机送到西湖风景区，6人出行需要7座车。
#   6位乘客包括：王芳、刘强、小明、小红、陈静、吴勇
#   需要创建2个订单：
#   1. 航班订单（3天后成都→杭州萧山）
#   2. 接机订单（萧山国际机场→西湖风景区，经济7座，接机航班到达后30分钟）
#
# 业务流程:
#   1. 搜索并预订3天后成都到杭州的航班（到达萧山国际机场）
#   2. 记录航班到达时间和到达机场位置
#   3. 选择"接我"服务（from_airport = 从机场接到目的地）
#   4. 上车点：萧山国际机场（通过航班信息自动确定）
#   5. 下车点：西湖风景区（目的地）
#   6. 用车时间：航班到达时间后30分钟
#   7. 筛选经济7座车型（6人+行李必须7座车）
#   8. 选择该车型中价格最低的套餐
#
# 复杂度分析:
#   1. 需要搜索并预订3天后成都到杭州的航班
#   2. 需要识别航班到达机场（萧山国际机场）
#   3. 需要预订接机服务，起点必须匹配航班到达机场
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 需要根据人数选择经济7座车型（6人+行李需要7座车）
#   6. 需要选择该车型中价格最低的套餐
#   ❌ 不能一次性提供：需要先预订航班→获取到达信息→选择接机服务→上车点自动匹配→选择下车点→计算接送时间→筛选车型→对比价格→预订
#
# 评分标准（总分100分）:
#   1. 创建了航班订单（3天后成都→杭州萧山）(15分)
#   2. 创建了接机订单 (15分)
#   3. 接机起点正确（萧山国际机场）(15分)
#   4. 接机终点正确（西湖风景区）(15分)
#   5. 接送时间正确（航班到达后30分钟）(15分)
#   6. 车型正确（经济7座，适合6人出行）(10分)
#   7. 选择了该车型中价格最低的套餐 (10分)
#   8. 乘客信息正确（6位乘客：王芳、刘强、小明、小红、陈静、吴勇）(5分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v173_book_flight_and_airport_pickup_economy7_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V173BookFlightAndAirportPickupEconomy7Validator < BaseValidator
    self.validator_id = 'v173_book_flight_and_airport_pickup_economy7_validator'
    self.task_id = 'c85d1c59-9430-4f34-9f74-9064baa17824'
    self.title = '给王芳等6人预订3天后成都到杭州的航班，并预订萧山机场接机到西湖（王芳、刘强、小明、小红、陈静、吴勇，航班11:50到达萧山，经济7座最便宜套餐）'
    self.description = '帮王芳等6人（王芳、刘强、小明、小红、陈静、吴勇）订3天后从成都到杭州的航班，到达萧山机场后接机到西湖风景区，6人出行需要7座车'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '成都'
      @arrival_city = '杭州'
      @arrival_airport = '萧山国际机场'
      @destination_location = '西湖风景区'
      @flight_date = Date.current + 3.days  # 3天后出发
      @passenger_count = 6  # 6人出行
      @vehicle_category = 'economy_7'  # 经济7座
      @transfer_type = 'airport_pickup'
      @service_type = 'from_airport'
    
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      # 查询乘客信息（6位：王芳、刘强、小明、小红、陈静、吴勇）
      @passengers = user.passengers.where(data_version: 0).where(name: ['王芳', '刘强', '小明', '小红', '陈静', '吴勇']).to_a
      raise "未找到足够的乘客信息" if @passengers.size < 6
      @expected_passenger_names = @passengers.map(&:name)  # 存偨6个人的名字列表
    
      # 查找可用航班（到达萧山的航班）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%萧山%")
    
      expect(@available_flights).not_to be_empty, "数据包缺少3天后#{@departure_city}→#{@arrival_city}的航班（到达萧山）"
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
    
      # 查找经济7座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      expect(@available_packages).not_to be_empty, "数据包缺少经济7座套餐"
      return if @available_packages.empty?  # Guard clause
    
      @best_package = @available_packages.first
    
      # 获取示例航班的时间信息
      @example_flight = @available_flights.order(:departure_time).first
    
      {
        task: "请为王芳等6人（王芳、刘强、小明、小红、陈静、吴勇）预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@arrival_city}的航班（到达萧山国际机场），" \
              "并预订接机服务到#{@destination_location}（6人出行需要选择经济7座车型）",
        scenario: "3天后从#{@departure_city}坐飞机到#{@arrival_city}，王芳等6人到达萧山机场后需要接机送到#{@destination_location}",
        passengers: "王芳、刘强、小明、小红、陈静、吴勇",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.to_s,
          arrival_airport: "萧山国际机场",
          example_arrival_time: @example_flight.arrival_time.strftime('%H:%M'),
          example_pickup_time: (@example_flight.arrival_time + 30.minutes).strftime('%H:%M')
        },
        service_type: "机场接机（from_airport）",
        pickup_location: "萧山国际机场（上车点，通过#{@departure_city}→#{@arrival_city}航班到达信息自动确定）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_time_rule: "航班到达时间后30分钟",
        vehicle_category: '经济7座（economy_7，6人+行李必须7座车）',
        flow_hint: "1. 搜索并预订#{@departure_city}→#{@arrival_city}航班（3天后，到达萧山，如#{@example_flight.arrival_time.strftime('%H:%M')}到达） → 2. 记录航班到达时间 → 3. 选择接机服务 → 4. 上车点自动=萧山国际机场 → 5. 下车点输入#{@destination_location} → 6. 用车时间=航班到达后30分钟（#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}接机） → 7. 筛选经济7座车型（6人出行必须7座） → 8. 选择该车型价格最低的套餐",
        hint: "先预订航班（#{@example_flight.arrival_time.strftime('%H:%M')}到达萧山），然后预订接机服务（接机时间=航班到达时间+30分钟=#{(@example_flight.arrival_time + 30.minutes).strftime('%H:%M')}），起点为萧山国际机场，终点为#{@destination_location}，6人出行必须选择经济7座车型中价格最低的套餐",
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
      # 断言1: 创建了航班订单（3天后成都→杭州萧山）(15%)
      add_assertion "创建了航班订单（3天后#{@departure_city}→#{@arrival_city}萧山）", weight: 15 do
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
    
      # 断言3: 接机起点正确（萧山国际机场）(15%)
      add_assertion "接机起点正确（萧山国际机场）", weight: 15 do
        # 验证上车点包含萧山
        expect(@transfer.location_from).to include('萧山'),
          "接机起点错误。期望包含: 萧山国际机场, 实际: #{@transfer.location_from}"
      end
    
      # 断言4: 接机终点正确（西湖风景区）(15%)
      add_assertion "接机终点正确（#{@destination_location}）", weight: 15 do
        # 验证下车点包含西湖风景区
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
    
      # 断言6: 车型正确（经济7座，适合6人出行）(10%)
      add_assertion "车型正确（经济7座，6人出行必须7座车）", weight: 10 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车型选择错误。期望: #{@vehicle_category}（经济7座，6人+行李必须7座车），实际: #{@transfer.transfer_package.vehicle_category}"
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
    
      # 断言8: 乘客信息正确（6位乘客：王芳、刘强、小明、小红、陈静、吴勇）(5%)
      add_assertion "为6位乘客都创建了航班订单（王芳、刘强、小明、小红、陈静、吴勇）", weight: 5 do
        # 方式1: 通过booking_group_id查询团体订单
        if @flight_booking.booking_group_id.present?
          group_bookings = @flight_booking.group_bookings.to_a
          passenger_names = group_bookings.map(&:passenger_name).sort
          
          expect(group_bookings.size).to eq(6),
            "航班订单数量错误。期望为6人创建6个订单，实际创建了#{group_bookings.size}个订单"
          
          # 验证6个乘客名字都在预期列表中
          passenger_names.each do |name|
            expect(@expected_passenger_names).to include(name),
              "发现未预期的乘客：#{name}。期望的6位乘客：#{@expected_passenger_names.join('、')}"
          end
          
          # 验证所有预期乘客都有订单
          @expected_passenger_names.each do |name|
            expect(passenger_names).to include(name),
              "缺少乘客#{name}的航班订单。已创建订单的乘客：#{passenger_names.join('、')}"
          end
        else
          # 方式2: 没有booking_group_id，查询同航班同日期的所有订单
          all_bookings = Booking
            .joins(:flight)
            .where(flights: { 
              departure_city: @departure_city, 
              destination_city: @arrival_city,
              flight_date: @flight_date
            })
            .where(data_version: @data_version)
            .to_a
          
          passenger_names = all_bookings.map(&:passenger_name).sort
          
          expect(all_bookings.size).to be >= 6,
            "航班订单数量不足。期望至少6个订单（6位乘客），实际找到#{all_bookings.size}个订单"
          
          # 验证所有预期乘客都有订单
          missing_passengers = @expected_passenger_names.reject { |name| passenger_names.include?(name) }
          expect(missing_passengers).to be_empty,
            "缺少以下乘客的航班订单：#{missing_passengers.join('、')}。已创建订单的乘客：#{passenger_names.join('、')}"
        end
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      # 获取6位乘客信息
      passengers = @passengers
      raise "未找到6位乘客信息" if passengers.size < 6
    
      # 步骤1: 为6位乘客预订航班（3天后成都→杭州萧山）
      target_flight = @available_flights.order(:departure_time).first
      raise "未找到可用航班" unless target_flight
    
      flight_offer = target_flight.flight_offers.order(:price).first
      raise "航班没有可用套餐" unless flight_offer
    
      # 生成团体订单ID，关联6个订单
      booking_group_id = SecureRandom.uuid
      
      # 为每个乘客创建独立的航班订单
      flight_bookings = passengers.map do |passenger|
        Booking.create!(
          user_id: user.id,
          flight_id: target_flight.id,
          flight_offer_id: flight_offer.id,
          booking_group_id: booking_group_id,  # 关联同组订单
          passenger_name: passenger.name,
          passenger_id_number: passenger.id_number,
          contact_phone: passenger.phone,
          total_price: flight_offer.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 使用第一个订单作为代表（后续通过booking_group_id查找全部）
      flight_booking = flight_bookings.first
    
      # 步骤2: 预订接机服务（萧山国际机场→西湖风景区，经济7座，接机时间=航班到达后30分钟）
      pickup_datetime = target_flight.arrival_time + 30.minutes
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @airport_location.name,
        location_to: @destination.name,
        pickup_datetime: pickup_datetime,
        passenger_name: passengers.first.name,  # 接机联系人（可以是任何一个乘客）
        passenger_phone: passengers.first.phone,
        passenger_count: @passenger_count,
        luggage_count: 4,
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
        passenger_count: @passenger_count,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type,
        expected_passenger_names: @expected_passenger_names,
      }
    end
  
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_airport = data['arrival_airport']
      @destination_location = data['destination_location']
      @flight_date = Date.parse(data['flight_date'])
      @passenger_count = data['passenger_count']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_names = data['expected_passenger_names'] || ['王芳', '刘强', '小明', '小红', '陈静', '吴勇']
    
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passengers = user.passengers.where(data_version: 0).where(name: @expected_passenger_names).to_a
    
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%萧山%")
    
      @airport_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_airport,
        data_version: 0
      )
    
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        data_version: 0
      )
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      @best_package = @available_packages.first if @available_packages.any?
    end
  end
end
