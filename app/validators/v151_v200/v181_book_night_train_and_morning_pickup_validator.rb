# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例181: 给刘强预订明天北京到上海的夜间火车，并预订清晨接站服务（北京→上海，明天20:00后出发，上海火车站→陆家嘴金融区接送服务点）
#
# 任务描述:
#   刘强需要明天晚上从北京坐夜间火车到上海（20:00后出发，次日清晨到达），
#   到达上海站后需要接站服务。Agent需要搜索并预订夜间火车票，
#   然后根据火车到达时间预订清晨接站服务（下车点需从TransferLocation查询具体地点，如外滩、陆家嘴金融区等）。
#
# 业务流程（8个关键步骤）：
#   1. 搜索北京到上海的火车票（明天20:00后出发）
#   2. 筛选夜间火车（20:00-23:59出发，次日清晨到达）
#   3. 预订火车票（乘客刘强）
#   4. 确认火车到达站（上海站或上海虹桥站）
#   5. 选择接站服务（from_station = 从车站接到目的地）
#   6. 接送时间自动计算（火车到达时间，清晨）
#   7. 选择下车点（从TransferLocation查询具体地点，如外滩、陆家嘴金融区等）
#   8. 预订接站服务（送到具体地点）
#
# 复杂度分析（8个关键点）：
#   1. 需要识别夜间火车（20:00后出发）
#   2. 需要理解清晨到达的含义（次日早上）
#   3. 需要搜索并预订夜间火车票（北京→上海，20:00后）
#   4. 需要识别火车到达站（上海站或上海虹桥站）作为接站起点
#   5. 需要从TransferLocation查询上海的具体下车点（外滩、陆家嘴金融区等，不能用模糊的"市区"）
#   6. 需要选择具体目的地作为接站终点
#   7. 需要自动计算接送时间（火车到达时间，清晨）
#   8. 需要验证接站时间与火车到达时间匹配（0-2小时内）
#   ❌ 不能一次性提供：需要先预订火车票→确认到达站和到达时间→选接站服务→选择具体下车点→设置时间→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了火车订单和接站订单（20分）
#   - 火车出发时间正确（20:00后）（18分）
#   - 创建了接站订单（15分）
#   - 接站起点正确（上海火车站）（8分）
#   - 接站终点正确（TransferLocation中的具体地点）（7分）
#   - 接站时间与火车到达时间匹配（0-2小时内）（17分）
#   - 火车乘客信息正确（刘强）（7分）
#   - 接站联系人信息正确（刘强）（8分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v181_book_night_train_and_morning_pickup_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V181BookNightTrainAndMorningPickupValidator < BaseValidator
    self.validator_id = 'v181_book_night_train_and_morning_pickup_validator'
    self.task_id = '20114593-e2f1-4fc7-9ded-aa5c49df72a3'
    self.title = '给刘强预订明天北京到上海的夜间火车，并预订清晨接站服务（北京→上海，明天20:00后出发，上海火车站→陆家嘴金融区接送服务点）'
    self.description = '帮刘强订明天晚上从北京到上海的夜间火车（20:00后出发），并预订清晨接站服务（下车点需选择具体地点，如外滩、陆家嘴金融区等）'
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
      
      # 查找上海的具体下车点（从TransferLocation）
      @destination_location = TransferLocation.find_by(
        city: @arrival_city,
        location_type: 'other',
        data_version: 0
      )
      
      expect(@destination_location).not_to be_nil, "数据包缺少#{@arrival_city}的接站下车点（TransferLocation）"
      @destination_name = @destination_location.name
      
      # 计算火车到达时间
      @sample_train = @available_trains.first
      @arrival_datetime = @sample_train.arrival_time
      
      {
        task: "请为#{@passenger.name}预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的夜间火车（20:00后出发），" \
              "并预订清晨接站服务到#{@destination_name}",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          departure_time: "20:00后",
          pickup_location: "#{@arrival_city}火车站（上车点，通过火车票确定）",
          dropoff_location: "#{@destination_name}（下车点，目的地）",
          pickup_service: "清晨接站"
        },
        hint: "夜间火车清晨到达，预订接站服务避免打车困难，下车点需要选择具体地点（如外滩、陆家嘴金融区等）",
        statistics: {
          available_night_trains: @available_trains.count,
          available_transfers: @available_transfers.count,
          destination_location: @destination_name
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
        location_to: @destination_location.name,  # 使用TransferLocation中的具体地点
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
      
      # 断言4: 接站起点正确（火车站） (8%)
      add_assertion "接站起点正确（#{@arrival_city}火车站）", weight: 8 do
        location_from_correct = @transfer_order.location_from&.include?(@arrival_city) && 
                               (@transfer_order.location_from&.include?('站') || @transfer_order.location_from&.include?('火车'))
        
        expect(location_from_correct).to be(true),
          "接站起点错误。期望: #{@arrival_city}火车站, 实际: #{@transfer_order.location_from}"
      end
      
      # 断言5: 接站终点正确（#{@destination_name}） (7%)
      add_assertion "接站终点正确（#{@destination_name}）", weight: 7 do
        expect(@transfer_order.location_to).to eq(@destination_name),
          "接站终点错误。期望: #{@destination_name}（TransferLocation中的具体地点），实际: #{@transfer_order.location_to}"
      end
      
      # 断言6: 接站时间与火车到达时间匹配 (17%)
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
    
      # 断言7: 火车乘客信息正确（刘强） (7%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
    
      # 断言8: 接站联系人信息正确（刘强） (8%)
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
        destination_name: @destination_name,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @arrival_datetime = DateTime.parse(data['arrival_datetime']) if data['arrival_datetime']
      @destination_name = data['destination_name']
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
      
      @destination_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_name,
        data_version: 0
      )
      
      @sample_train = @available_trains.first if @available_trains.any?
    end
  end
end
