# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例174: 国际航班到达后预订接机服务
#
# 任务描述:
#   用户订了国际航班，到达上海浦东国际机场T2航站楼（深夜22:00到达），需要接机到陆家嘴金融区。
#   需要创建2个订单：
#   - 1个航班订单（国际航班→上海浦东T2）
#   - 1个接机订单（浦东T2 → 陆家嘴金融区）
#
# 复杂度分析:
#   1. 需要搜索并预订到达上海浦东T2的航班
#   2. 需要识别航班到达机场（浦东T2，不同于T1）
#   3. 深夜接机服务
#   4. 接送时间需要自动计算（航班到达后30分钟）
#   5. 选择经济5座并选择最优价格
#
# 评分标准:
#   - 创建了航班订单和接机订单 (20分)
#   - 航班到达机场正确（浦东T2）(15分)
#   - 接机起点正确（浦东T2，注意不是T1）(20分)
#   - 接机终点正确（陆家嘴金融区）(15分)
#   - 接送时间正确（深夜22:30）(15分)
#   - 价格选择合理（15分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v174_book_international_flight_and_pickup_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V174BookInternationalFlightAndPickupValidator < BaseValidator
    self.validator_id = 'v174_book_international_flight_and_pickup_validator'
    self.task_id = '6c54e97f-e56a-441b-adcb-a0be3cb045e2'
    self.title = '国际航班3天后到达后预订接机服务'
    self.description = '订购国际航班到达上海浦东T2（深夜），预订接机到陆家嘴金融区'
    self.timeout_seconds = 300
  
    def prepare
      @arrival_city = '上海'
      @arrival_airport = '浦东国际机场T2航站楼'
      @destination_location = '陆家嘴金融区'
      @flight_date = Date.current + 3.days
      @arrival_hour = 22  # 深夜到达
      @vehicle_category = 'economy_5'
      @transfer_type = 'airport_pickup'
      @service_type = 'from_airport'
    
      @available_flights = Flight.where(
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%浦东%T2%")
       .select { |f| f.arrival_time.hour >= @arrival_hour - 2 }
    
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
    
      raise "未找到经济5座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}到达#{@arrival_city}浦东国际机场T2航站楼的国际航班（深夜22:00左右到达），" \
              "并预订接机服务到#{@destination_location}（经济5座）",
        requirements: {
          arrival_city: @arrival_city,
          arrival_airport: @arrival_airport,
          flight_date: @flight_date.to_s,
          arrival_time: '深夜22:00左右',
          destination: @destination_location,
          vehicle_category: '经济5座',
          service_description: '深夜接机服务'
        },
        hint: "注意到达航站楼是T2（不是T1）。深夜接机，接机时间应为航班到达后30分钟（约22:30）",
        statistics: {
          available_flights: @available_flights.count,
          available_packages: @available_packages.count
        }
      }
    end
  
    def verify
      add_assertion "创建了航班订单和接机订单", weight: 20 do
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@flight_bookings).not_to be_empty, "未找到到达#{@arrival_city}的航班订单"
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
    
      add_assertion "航班到达机场正确（浦东T2）", weight: 15 do
        flight = @flight_booking.flight
        airport_matches = flight.arrival_airport.include?('浦东') && flight.arrival_airport.include?('T2')
        
        expect(airport_matches).to be_truthy,
          "航班到达机场错误。期望: 浦东T2, 实际: #{flight.arrival_airport}"
      end
    
      add_assertion "接机起点正确（浦东T2，不是T1）", weight: 20 do
        location_matches = @transfer.location_from.include?('浦东') && @transfer.location_from.include?('T2')
        
        expect(location_matches).to be_truthy,
          "接机起点错误。期望: #{@arrival_airport}（浦东T2，不是T1），实际: #{@transfer.location_from}"
      end
    
      add_assertion "接机终点正确（#{@destination_location}）", weight: 15 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接机终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "接送时间正确（深夜，航班到达后30分钟）", weight: 15 do
        flight = @flight_booking.flight
        expected_pickup_time = flight.arrival_time + 30.minutes
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "价格选择合理", weight: 15 do
        cheapest_price = TransferPackage
          .where(vehicle_category: @vehicle_category, data_version: @data_version)
          .minimum(:price)
      
        if cheapest_price.present?
          expect(@transfer.total_price).to be <= (cheapest_price * 1.05),
            "未选择最优价格。最低价: ¥#{cheapest_price}, 实际: ¥#{@transfer.total_price}"
        end
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_flight = @available_flights.sort_by(&:arrival_time).last
      raise "未找到可用航班" unless target_flight
    
      flight_offer = target_flight.flight_offers.order(:price).first
      raise "航班没有可用套餐" unless flight_offer
    
      flight_booking = Booking.create!(
        user_id: user.id,
        flight_id: target_flight.id,
        flight_offer_id: flight_offer.id,
        passenger_name: '赵六',
        passenger_id_number: '310101199201011234',
        contact_phone: '13600136000',
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
        passenger_name: '赵六',
        passenger_phone: '13600136000',
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
        arrival_city: @arrival_city,
        arrival_airport: @arrival_airport,
        destination_location: @destination_location,
        flight_date: @flight_date.to_s,
        arrival_hour: @arrival_hour,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type
      }
    end
  
    def restore_from_state(data)
      @arrival_city = data['arrival_city']
      @arrival_airport = data['arrival_airport']
      @destination_location = data['destination_location']
      @flight_date = Date.parse(data['flight_date'])
      @arrival_hour = data['arrival_hour']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
    
      @available_flights = Flight.where(
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("arrival_airport LIKE ?", "%浦东%T2%")
       .select { |f| f.arrival_time.hour >= @arrival_hour - 2 }
    
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
