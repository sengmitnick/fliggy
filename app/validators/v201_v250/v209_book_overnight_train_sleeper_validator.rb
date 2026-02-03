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
#   - 出发日期正确（后天） (15%)
#   - 出发时间在22:00-次日08:00夜间时段 (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V209BookOvernightTrainSleeperValidator < BaseValidator
    self.validator_id = 'v209_book_overnight_train_sleeper_validator'
    self.task_id = '8f9910f3-9f9f-4f2f-ff2f-3f5a6b7c8d9f'
    self.title = '预订夜间卧铺火车'
    self.description = '用户需要预订后天北京→西安，夜间卧铺（22:00-次日08:00）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '西安'
      @travel_date = Date.today + 2.days
      
      # 查找夜间火车（22:00-次日08:00出发）
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        # 22:00-23:59 或 00:00-08:00
        (hour >= 22) || (hour < 8)
      end
      
      raise "未找到符合条件的夜间火车" if @available_trains.empty?
      
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
      
      add_assertion "出发日期正确（后天#{@travel_date}）", weight: 15 do
        actual_date = @booking.train.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（后天）, 实际: #{actual_date}"
      end
      
      add_assertion "出发时间在22:00-次日08:00夜间时段", weight: 30 do
        hour = @booking.train.departure_time.hour
        is_overnight = (hour >= 22) || (hour < 8)
        expect(is_overnight).to eq(true),
          "非夜间时段。期望: 22:00-次日08:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择夜间时段的火车（优先选择22:00-24:00之间的）
      preferred = @available_trains.select { |t| t.departure_time.hour >= 22 }
      train = (preferred.presence || @available_trains).min_by(&:price_second_class)
      
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
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
        travel_date: @travel_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        (hour >= 22) || (hour < 8)
      end
    end
  end
end
