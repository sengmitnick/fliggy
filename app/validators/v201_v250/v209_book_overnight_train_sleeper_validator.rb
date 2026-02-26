# frozen_string_literal: true

require_relative '../base_validator'

# V209: 预订夜间卧铺火车
#
# 任务描述:
#   用户需要预订后天北京→西安，夜间卧铺（22:00-次日08:00）
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 火车路线正确（北京→西安） (15%)
#   - 出发时间在22:00-次日08:00夜间时段 (45%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V209BookOvernightTrainSleeperValidator < BaseValidator
    self.validator_id = 'v209_book_overnight_train_sleeper_validator'
    self.task_id = '8f9910f3-9f9f-4f2f-ff2f-3f5a6b7c8d9f'
    self.title = '张三需要预订后天从北京到西安的夜间卧铺火车，出发时间在22:00-次日08:00之间'
    self.description = '张三需要预订后天从北京到西安的夜间卧铺火车，出发时间在22:00-次日08:00之间'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '西安'
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找夜间火车（22:00-次日08:00出发，不限定日期）
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        # 22:00-23:59 或 00:00-08:00
        (hour >= 22) || (hour < 8)
      end
      
      raise "未找到符合条件的夜间火车" if @available_trains.empty?
      
      @travel_date = @available_trains.first.departure_time.to_date
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）晚上22:00-次日早上08:00从#{@departure_city}到#{@arrival_city}的夜间卧铺火车，适合省时间边睡觉边赶路。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          time_window: '22:00-次日08:00',
          purpose: '夜间卧铺'
        },
        hint: "选择夜间时段出发的火车，出发时间在22:00-次日08:00之间。"
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @booking = all_bookings.first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
      end
      
      return if @booking.nil?
      
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.train.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.train.arrival_city}"
      end
      
      # 移除日期验证（数据包中日期固定）
      
      add_assertion "出发时间在22:00-次日08:00夜间时段", weight: 45 do
        hour = @booking.train.departure_time.hour
        is_overnight = (hour >= 22) || (hour < 8)
        expect(is_overnight).to eq(true),
          "非夜间时段。期望: 22:00-次日08:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}（#{@expected_passenger_name}）, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择夜间时段的火车（优先选择22:00-24:00之间的）
      preferred = @available_trains.select { |t| t.departure_time.hour >= 22 }
      train = (preferred.presence || @available_trains).min_by(&:price_second_class)
      
      # 使用 prepare 中预查询的乘客数据
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: train.price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        (hour >= 22) || (hour < 8)
      end
    end
  end
end
