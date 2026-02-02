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
    self.title = '预订夜间火车和清晨接站服务'
    self.description = '用户需要预订夜间火车（晚上8点后出发），并预订清晨接站服务'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.tomorrow + 2.days
      
      # 查找夜间火车（20:00后出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 20 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}夜间火车（20:00后）"
      
      # 查找上海的接站服务
      @available_transfers = Transfer
        .where("pickup_location LIKE ? OR city LIKE ?", "%#{@arrival_city}%", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_transfers).not_to be_empty, "数据包缺少#{@arrival_city}的接站服务"
      
      # 计算火车到达时间
      @sample_train = @available_trains.first
      @arrival_datetime = @sample_train.arrival_time
      
      {
        task: "请预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.today).to_i}天后）从#{@departure_city}到#{@arrival_city}的夜间火车（20:00后出发），" \
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
      
      # 创建火车订单
      train = @available_trains.first
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'sleeper',
        quantity: 1,
        total_price: train.price_sleeper || train.price_first_class,
        data_version: @data_version
      )
      
      # 创建接站订单
      transfer = @available_transfers.first
      TransferOrder.create!(
        user: user,
        transfer: transfer,
        passenger_name: user.name,
        contact_phone: '13800138000',
        pickup_date: train.arrival_time.to_date,
        pickup_time: train.arrival_time,
        passenger_count: 1,
        total_price: transfer.price,
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
      
      # 断言2: 火车出发时间正确（20:00后） (20%)
      add_assertion "火车出发时间正确（20:00后）", weight: 20 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= 20, 
          "出发时间过早。期望: 20:00后, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了接站订单 (20%)
      add_assertion "创建了接站订单", weight: 20 do
        @transfer_order = TransferOrder
          .joins(:transfer)
          .includes(:transfer)
          .where("transfers.pickup_location LIKE ? OR transfers.city LIKE ?", "%#{@arrival_city}%", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer_order).not_to be_nil, "未找到接站订单"
      end
      
      return if @transfer_order.nil?
      
      # 断言4: 接站地点正确（到达城市） (20%)
      add_assertion "接站地点正确（#{@arrival_city}）", weight: 20 do
        transfer = @transfer_order.transfer
        location_correct = transfer.pickup_location&.include?(@arrival_city) || 
                          transfer.city&.include?(@arrival_city)
        
        expect(location_correct).to be true,
          "接站地点错误。期望: #{@arrival_city}, 实际: #{transfer.pickup_location || transfer.city}"
      end
      
      # 断言5: 接站时间与火车到达时间匹配 (20%)
      add_assertion "接站时间与火车到达时间匹配", weight: 20 do
        train_arrival = @train_booking.train.arrival_time
        pickup_datetime = @transfer_order.pickup_time
        
        # 接站时间应该在火车到达后的合理时间内（0-2小时）
        time_diff = (pickup_datetime - train_arrival) / 3600.0  # 小时
        
        expect(time_diff).to be >= -0.5,
          "接站时间过早。期望: 火车到达后, 实际: 早#{-time_diff.round(1)}小时"
        expect(time_diff).to be <= 2,
          "接站时间过晚。期望: 火车到达后2小时内, 实际: 晚#{time_diff.round(1)}小时"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date&.to_s,
        arrival_datetime: @arrival_datetime&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @arrival_datetime = DateTime.parse(data['arrival_datetime']) if data['arrival_datetime']
    end
  end
end
