# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例206: 给张三预订明天清晨早班火车（时间窗口05:00-07:00，上海→南京）
#
# 任务描述:
#   张三明天需要从上海到南京，要求预订清晨05:00-07:00的早班火车。
#   Agent需要理解清晨时段的定义，筛选符合时间要求的高铁并完成预订。
#
# 业务流程:
#   1. 搜索上海→南京高铁（明天）
#   2. 筛选出发时间在05:00-07:00之间的早班车
#   3. 从符合清晨时段的高铁中选择一个
#   4. 填写乘客信息（张三）
#   5. 确认订单
#
# 复杂度分析:
#   1. 需要理解清晨早班的定义（05:00-07:00黎明时段）
#   2. 需要在特定时间窗口内筛选车次
#   3. 需要正确填写乘客信息
#   4. 需要理解"明天"的时间概念
#
# 评分标准:
#   - 创建了火车票订单 (20分)
#   - 火车路线正确（上海→南京） (15分)
#   - 出发时间在05:00-07:00清晨时段 (45分)
#   - 乘客信息正确 (10分)
#   - 订单状态有效 (10分)
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
      @sample_train = @available_trains.min_by { |t| t.departure_time }
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）清晨05:00-07:00从#{@departure_city}到#{@arrival_city}的最早班次高铁，适合早起赶路。",
        scenario: "#{@expected_passenger_name}明天需要从#{@departure_city}到#{@arrival_city}，选择清晨早班（05:00-07:00）以便早到达目的地",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          time_window: '05:00-07:00',
          passenger: @expected_passenger_name,
          purpose: '清晨早班'
        },
        available_trains_sample: {
          count: @available_trains.count,
          example: "#{@sample_train.train_number}（#{@sample_train.departure_time.strftime('%H:%M')}出发，二等座#{@sample_train.price_second_class}元）"
        },
        hint: "选择清晨时段的高铁，出发时间在05:00-07:00之间。"
      }
    end
    
    def verify
      # 断言1: 创建了火车票订单 (20%)
      add_assertion "创建了火车票订单", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      # 断言2: 火车路线正确（上海→南京） (15%)
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.train.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.train.arrival_city}"
      end
      
      # 断言3: 出发时间在05:00-07:00清晨时段 (45%)
      add_assertion "出发时间在05:00-07:00清晨时段", weight: 45 do
        hour = @booking.train.departure_time.hour
        expect(hour).to be >= @time_window_start,
          "出发时间过早。期望: ≥#{@time_window_start}:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
        expect(hour).to be < @time_window_end,
          "出发时间过晚。期望: <#{@time_window_end}:00, 实际: #{@booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言4: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言5: 订单状态有效 (10%)
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
