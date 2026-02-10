# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例181: 预订夜间火车和清晨接站服务
#
# 任务描述:
#   用户需要预订夜间火车（晚上8点后出发），并预订清晨接站服务
#
# 复杂度分析:
#   1. 需要筛选夜间火车（20:00后出发）
#   2. 需要预订清晨接站服务
#   3. 验证接站时间与火车到达时间匹配
#
# 评分标准:
#   - 创建了火车订单 (20分)
#   - 火车出发时间正确（20:00后） (20分)
#   - 创建了接站订单 (20分)
#   - 接站地点正确（到达城市） (20分)
#   - 接站时间与火车到达时间匹配 (20分)
module V151V200
  class V181BookNightTrainAndMorningPickupValidator < BaseValidator
    self.validator_id = 'v181_book_night_train_and_morning_pickup_validator'
    self.task_id = '20114593-e2f1-4fc7-9ded-aa5c49df72a3'
    self.title = '给刘强预订明天北京到上海的夜间火车，并预订清晨接站服务'
    self.description = '帮刘强订明天晚上从北京到上海的夜间火车（20:00后出发），并预订清晨接站服务'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.current + 1.day  # 明天
      
      # 查找夜间火车（20:00后出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 20 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}夜间火车（20:00后）"
      
      # 查找上海的接站服务
      @available_transfers = TransferPackage
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_transfers).not_to be_empty, "数据包缺少#{@arrival_city}的接站服务"
      
      # 计算火车到达时间
      @sample_train = @available_trains.first
      @arrival_datetime = @sample_train.arrival_time
      
      {
        task: "请为#{@passenger.name}预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的夜间火车（20:00后出发），" \
              "并预订清晨接站服务",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          departure_time: "20:00后",
          pickup_location: "#{@arrival_city}火车站",
          pickup_service: "清晨接站"
        },
        hint: "夜间火车清晨到达，预订接站服务避免打车困难",
        statistics: {
          available_night_trains: @available_trains.count,
          available_transfers: @available_transfers.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # 创建火车订单
      train = @available_trains.first
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'business_class',
        accept_terms: true,
        total_price: train.price_business_class,
        data_version: @data_version
      )
      
      # 创建接站订单
      transfer_package = @available_transfers.first
      Transfer.create!(
        user: user,
        transfer_package: transfer_package,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: "#{@arrival_city}火车站",
        location_to: "#{@arrival_city}市区",
        pickup_datetime: train.arrival_time,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        passenger_count: 1,
        total_price: transfer_package.price,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了火车订单 (20%)
      add_assertion "创建了火车订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车订单"
      end
      
      return if @train_booking.nil?
      
      # 断言2: 火车出发时间正确（20:00后） (18%)
      add_assertion "火车出发时间正确（20:00后）", weight: 18 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= 20, 
          "出发时间过早。期望: 20:00后, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了接站订单 (15%)
      add_assertion "创建了接站订单", weight: 15 do
        @transfer_order = Transfer
          .where("location_from LIKE ? OR location_to LIKE ?", "%#{@arrival_city}%", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer_order).not_to be_nil, "未找到接站订单"
      end
      
      return if @transfer_order.nil?
      
      # 断言4: 接站地点正确（到达城市） (15%)
      add_assertion "接站地点正确（#{@arrival_city}）", weight: 15 do
        location_correct = @transfer_order.location_from&.include?(@arrival_city) || 
                          @transfer_order.location_to&.include?(@arrival_city)
        
        expect(location_correct).to be(true),
          "接站地点错误。期望: #{@arrival_city}, 实际: #{@transfer_order.location_from} → #{@transfer_order.location_to}"
      end
      
      # 断言5: 接站时间与火车到达时间匹配 (17%)
      add_assertion "接站时间与火车到达时间匹配", weight: 17 do
        train_arrival = @train_booking.train.arrival_time
        pickup_datetime = @transfer_order.pickup_datetime
        
        # 接站时间应该在火车到达后的合理时间内（0-2小时）
        time_diff = (pickup_datetime - train_arrival) / 3600.0  # 小时
        
        expect(time_diff).to be >= -0.5,
          "接站时间过早。期望: 火车到达后, 实际: 早#{-time_diff.round(1)}小时"
        expect(time_diff).to be <= 2,
          "接站时间过晚。期望: 火车到达后2小时内, 实际: 晚#{time_diff.round(1)}小时"
      end
    
      # 断言6: 火车乘客信息正确（刘强） (7%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
    
      # 断言7: 接站联系人信息正确（刘强） (8%)
      add_assertion "接站联系人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@transfer_order.passenger_name).to eq(@expected_passenger_name),
          "接站联系人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer_order.passenger_name}"
        expect(@transfer_order.passenger_phone).to eq(@expected_phone),
          "接站联系电话错误。期望: #{@expected_phone}, 实际: #{@transfer_order.passenger_phone}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date&.to_s,
        arrival_datetime: @arrival_datetime&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @arrival_datetime = DateTime.parse(data['arrival_datetime']) if data['arrival_datetime']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用火车和接站服务（用于simulate阶段）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 20 }
      
      @available_transfers = TransferPackage
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      @sample_train = @available_trains.first if @available_trains.any?
    end
  end
end
