# frozen_string_literal: true

require_relative '../base_validator'

# V206: 预订清晨早班火车
#
# 任务描述:
#   用户需要预订明天05:00-07:00最早班次上海→南京高铁
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 火车路线正确（上海→南京） (15%)
#   - 出发时间在05:00-07:00清晨时段 (45%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V206BookSunriseTrainEarlyBirdValidator < BaseValidator
    self.validator_id = 'v206_book_sunrise_train_early_bird_validator'
    self.task_id = '5e6687f0-6f6f-4f9c-cf9f-0f2a3b4c5d6e'
    self.title = '给张三预订明天清晨早班火车（时间窗口05:00-07:00，上海→南京）'
    self.description = '张三需要预订明天05:00-07:00从上海到南京的最早班次高铁'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '南京'
      @time_window_start = 5   # 05:00
      @time_window_end = 7     # 07:00
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找清晨早班火车（不限定日期）
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      raise "未找到符合条件的早班火车" if @available_trains.empty?
      
      @travel_date = @available_trains.first.departure_time.to_date
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）清晨05:00-07:00从#{@departure_city}到#{@arrival_city}的最早班次高铁，适合早起赶路。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          time_window: '05:00-07:00',
          purpose: '清晨早班'
        },
        hint: "选择清晨时段的高铁，出发时间在05:00-07:00之间。"
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
      
      add_assertion "出发时间在05:00-07:00清晨时段", weight: 45 do
        hour = @booking.train.departure_time.hour
        expect(hour).to be >= @time_window_start,
          "出发时间过早。期望: ≥#{@time_window_start}:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
        expect(hour).to be < @time_window_end,
          "出发时间过晚。期望: <#{@time_window_end}:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
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
      
      # 选择符合清晨时段的火车（优先选择最早的）
      train = @available_trains.min_by { |t| t.departure_time }
      
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
        time_window_start: @time_window_start,
        time_window_end: @time_window_end,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @time_window_start = data['time_window_start']
      @time_window_end = data['time_window_end']
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
        hour >= @time_window_start && hour < @time_window_end
      end
    end
  end
end
