# frozen_string_literal: true

require_relative '../base_validator'

# V203: 预订下午高铁（时间窗口）
#
# 任务描述:
#   用户需要预订后天14:00-17:00上海→杭州高铁（下午茶时段出发）
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 火车路线正确（上海→杭州） (15%)
#   - 出发日期正确（后天） (15%)
#   - 出发时间在14:00-17:00窗口内 (30%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V203BookAfternoonTrainTimeWindowValidator < BaseValidator
    self.validator_id = 'v203_book_afternoon_train_time_window_validator'
    self.task_id = '0b2354d7-2e2f-4c89-bc6e-7e9f8a0b1c2d'
    self.title = '给张三预订后天下午高铁（时间窗口14:00-17:00，上海→杭州）'
    self.description = '张三需要预订后天14:00-17:00从上海到杭州的高铁，适合下午茶时段出行'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @travel_date = Date.current + 2.days
      @time_window_start = 14  # 14:00
      @time_window_end = 17    # 17:00
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找符合时间窗口的火车
      all_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      raise "未找到符合条件的火车" if @available_trains.empty?
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）下午14:00-17:00从#{@departure_city}到#{@arrival_city}的高铁，适合下午茶时段出发。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          time_window: '14:00-17:00',
          purpose: '下午茶时段出行'
        },
        hint: "选择下午时段的高铁，出发时间在14:00-17:00之间。"
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
      
      add_assertion "出发时间在14:00-17:00窗口内", weight: 30 do
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
      
      # 选择符合时间窗口的火车（优先选择二等座价格低的）
      train = @available_trains.min_by(&:price_second_class)
      
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
        .by_date(@travel_date)
        .where(data_version: 0)
      
      @available_trains = all_trains.select do |t|
        hour = t.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
    end
  end
end
