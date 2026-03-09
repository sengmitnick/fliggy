# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例173: 订购机票后预订接机服务（经济7座，多人出行）
#
# 任务描述:
#   家庭出游（6人），订了成都到杭州的机票，到达萧山国际机场，需要接机到西湖风景区。
#   需要创建2个订单：
#   - 1个航班订单（成都→杭州萧山机场）
#   - 1个接机订单（萧山机场 → 西湖风景区，经济7座）
#
# 复杂度分析:
#   1. 需要搜索并预订成都到杭州的航班
#   2. 需要识别航班到达机场（萧山机场）
#   3. 需要根据人数选择经济7座车型（6人+行李需要7座车）
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 选择最优价格
#
# 评分标准:
#   - 创建了航班订单和接机订单 (20分)
#   - 航班路线正确（成都→杭州）(10分)
#   - 接机起点正确（萧山国际机场）(20分)
#   - 接机终点正确（西湖风景区）(15分)
#   - 接送时间正确（航班到达后30分钟）(10分)
#   - 车型选择正确（经济7座，适合6人出行）(25分)
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
    self.title = '给王芳等6人预订3天后成都到杭州的机票，并预订萧山机场接机到西湖（经济7座）'
    self.description = '帮王芳一家6个人订3天后从成都到杭州的航班，到达萧山机场后接机到西湖风景区，6人出行需要7座车'
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
    
      # 预查询乘客信息（王芳作为代表）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%萧山%")
    
      raise "未找到符合条件的航班" if @available_flights.empty?
    
      @airport_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_airport,
        location_type: 'airport',
        data_version: 0
      )
    
      raise "未找到机场位置: #{@arrival_airport}" unless @airport_location
    
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      raise "未找到目的地: #{@destination_location}" unless @destination
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      raise "未找到经济7座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请为王芳等6人预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班（到达萧山国际机场），" \
              "并预订接机服务到#{@destination_location}（注意：6人出行需要选择7座车）",
        requirements: {
          passenger: "#{@expected_passenger_name}等6人",
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_airport: @arrival_airport,
          flight_date: @flight_date.to_s,
          destination: @destination_location,
          passenger_count: @passenger_count,
          vehicle_category: '经济7座（6座车无法容纳6人+行李）',
          service_description: '接机服务（多人出行，需要7座车）'
        },
        hint: "6人出行加上行李，需要选择7座车（经济7座可载6人）。接机时间应为航班到达后30分钟",
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
      add_assertion "创建了航班订单和接机订单", weight: 20 do
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@flight_bookings).not_to be_empty, "未找到#{@departure_city}到#{@arrival_city}的航班订单"
        @flight_booking = @flight_bookings.first
      
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接机订单"
        @transfer = @transfers.first
      end
    
      return if @flight_booking.nil? || @transfer.nil?
    
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
      end
    
      add_assertion "接机起点正确（#{@arrival_airport}）", weight: 15 do
        # 使用TransferLocation数据库查询验证
        valid_airports = TransferLocation
          .where(city: @arrival_city, location_type: 'airport', data_version: 0)
          .where('name LIKE ?', '%萧山%')
          .pluck(:name)
        
        expect(valid_airports).to include(@transfer.location_from),
          "接机起点错误。期望: #{@arrival_airport}, 实际: #{@transfer.location_from}"
      end
    
      add_assertion "接机终点正确（#{@destination_location}）", weight: 15 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接机终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "接送时间正确（航班到达后30分钟）", weight: 7 do
        flight = @flight_booking.flight
        expected_pickup_time = flight.arrival_time + 30.minutes
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "车型选择正确（经济7座，适合6人出行）", weight: 18 do
        if @transfer.transfer_package.present?
          expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
            "车型选择错误。期望: #{@vehicle_category}（经济7座，6人出行必须7座车），实际: #{@transfer.transfer_package.vehicle_category}"
        end
      
        cheapest_price = TransferPackage
          .where(vehicle_category: @vehicle_category, data_version: @data_version)
          .minimum(:price)
      
        if cheapest_price.present?
          expect(@transfer.total_price).to be <= (cheapest_price * 1.05),
            "未选择最优价格。最低价: ¥#{cheapest_price}, 实际: ¥#{@transfer.total_price}"
        end
      end
    
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      add_assertion "接机联系人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "接机联系人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "接机联系电话错误。期望: #{@expected_phone}, 实际: #{@transfer.passenger_phone}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
    
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
      @passenger_count = data['passenger_count']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
    
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
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
