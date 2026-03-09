# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例172: 订购机票后预订接机服务（舒适5座）
#
# 任务描述:
#   商务人士订了广州到北京的机票，到达首都国际机场T3航站楼，需要接机到国贸CBD。
#   需要创建2个订单：
#   - 1个航班订单（广州→北京首都T3）
#   - 1个接机订单（首都T3 → 国贸CBD，舒适5座）
#
# 复杂度分析:
#   1. 需要搜索并预订广州到北京的航班
#   2. 需要识别航班到达机场（首都T3）
#   3. 需要预订接机服务，选择舒适5座车型
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 在舒适5座中选择最优价格或服务
#
# 评分标准:
#   - 创建了航班订单和接机订单 (20分)
#   - 航班路线正确（广州→北京）(10分)
#   - 接机起点正确（匹配航班到达机场首都T3）(20分)
#   - 接机终点正确（国贸CBD）(15分)
#   - 接送时间正确（航班到达后30分钟）(15分)
#   - 车型和价格选择合理（舒适5座，最优选择）(20分)
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
    
      raise "未找到机场位置: #{@arrival_airport}" unless @airport_location
    
      # 查找目的地位置
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      raise "未找到目的地: #{@destination_location}" unless @destination
    
      # 查找舒适5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      raise "未找到舒适5座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请为李四预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班（到达首都国际机场T3航站楼），" \
              "并预订接机服务到#{@destination_location}（选择舒适5座车型）",
        requirements: {
          passenger: @expected_passenger_name,
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_airport: @arrival_airport,
          flight_date: @flight_date.to_s,
          destination: @destination_location,
          vehicle_category: '舒适5座',
          service_description: '接机服务（商务用车，舒适体验）'
        },
        hint: "先预订航班，然后根据航班到达时间预订接机服务。接机时间应为航班到达后30分钟，起点为#{@arrival_airport}，终点为#{@destination_location}。" \
              "舒适5座比经济5座更舒适，适合商务出行",
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
      # 断言1: 创建了航班订单和接机订单 (20%)
      add_assertion "创建了航班订单和接机订单", weight: 20 do
        # 查找航班订单
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@flight_bookings).not_to be_empty, "未找到#{@departure_city}到#{@arrival_city}的航班订单"
        @flight_booking = @flight_bookings.first
      
        # 查找接机订单
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接机订单"
        @transfer = @transfers.first
      end
    
      return if @flight_booking.nil? || @transfer.nil?
    
      # 断言2: 航班路线正确 (10%)
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{flight.destination_city}"
      end
    
      # 断言3: 接机起点正确（匹配航班到达机场首都T3）(15%)
      add_assertion "接机起点正确（#{@arrival_airport}）", weight: 15 do
        flight = @flight_booking.flight
        expected_airport = flight.arrival_airport
      
        # 使用TransferLocation数据库查询验证
        valid_airports = TransferLocation
          .where(city: @arrival_city, location_type: 'airport', data_version: 0)
          .where('name LIKE ?', '%首都%')
          .where('name LIKE ?', '%T3%')
          .pluck(:name)
        
        expect(valid_airports).to include(@transfer.location_from),
          "接机起点错误。期望: #{expected_airport}（航班到达机场），实际: #{@transfer.location_from}"
      end
    
      # 断言4: 接机终点正确（国贸CBD）(15%)
      add_assertion "接机终点正确（#{@destination_location}）", weight: 15 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接机终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      # 断言5: 接送时间正确（航班到达后30分钟）(12%)
      add_assertion "接送时间正确（航班到达后30分钟）", weight: 12 do
        flight = @flight_booking.flight
        expected_pickup_time = flight.arrival_time + 30.minutes
      
        # 允许±10分钟误差
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（航班到达#{flight.arrival_time.strftime('%H:%M')}后30分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}（相差#{(time_diff / 60).to_i}分钟）"
      end
    
      # 断言6: 车型和价格选择合理（舒适5座，最优选择）(15%)
      add_assertion "车型和价格选择合理（舒适5座，最优选择）", weight: 15 do
        # 验证车型
        if @transfer.transfer_package.present?
          expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
            "车型选择错误。期望: #{@vehicle_category}（舒适5座），实际: #{@transfer.transfer_package.vehicle_category}"
        end
      
        # 验证价格选择（舒适5座有2个供应商，应选择最优的）
        cheapest_price = TransferPackage
          .where(vehicle_category: @vehicle_category, data_version: @data_version)
          .minimum(:price)
      
        if cheapest_price.present?
          # 允许选择价格稍高但服务更好的（如900游有"随时退·迟到赔"）
          expect(@transfer.total_price).to be <= (cheapest_price * 1.1),
            "价格选择不合理。最低价: ¥#{cheapest_price}, 实际: ¥#{@transfer.total_price}（允许选择服务更优的套餐）"
        end
      end
    
      # 断言7: 航班乘客信息正确（李四）(6%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 6 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      # 断言8: 接机联系人信息正确（李四）(7%)
      add_assertion "接机联系人信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "接机联系人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "接机联系电话错误。期望: #{@expected_phone}, 实际: #{@transfer.passenger_phone}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
    
      # 步骤1: 预订航班
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
    
      # 步骤2: 预订接机
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
        luggage_count: 1,
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
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
    
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%首都%T3%")
    
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
