# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例202: 给张三预订明天上午航班（时间窗口9:00-12:00，深圳→北京）
#
# 任务描述:
#   张三明天需要从深圳到北京出差，要求预订上午9:00-12:00时间窗口内的航班。
#   Agent需要理解时间窗口限制，筛选符合出发时间要求的航班并完成预订。
#
# 业务流程:
#   1. 搜索深圳→北京航班（明天）
#   2. 筛选出发时间在9:00-12:00之间的航班
#   3. 从符合时间窗口的航班中选择一个（可选择最便宜或时间最合适的）
#   4. 填写乘客信息（张三）
#   5. 确认订单
#
# 复杂度分析:
#   1. 需要理解时间窗口限制（9:00-12:00）
#   2. 需要筛选符合时间要求的航班
#   3. 需要从多个选项中选择合适的航班
#   4. 需要正确填写乘客信息
#   5. 需要理解"明天"的时间概念
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 航班路线正确（深圳→北京） (15分)
#   - 起飞日期正确（明天） (15分)
#   - 起飞时间在9:00-12:00窗口内 (30分)
#   - 乘客信息正确（张三） (10分)
#   - 订单状态有效 (10分)
module V201V250
  class V202BookMorningFlightTimeWindowValidator < BaseValidator
    self.validator_id = 'v202_book_morning_flight_time_window_validator'
    self.task_id = 'eab7dcf4-8b17-4de8-9f8b-98eaa110ac1f'
    self.title = '给张三预订明天上午航班（时间窗口9:00-12:00，深圳→北京）'
    self.description = '张三需要预订明天9:00-12:00从深圳到北京的航班，适合商务出行'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @arrival_city = '北京'
      @flight_date = Date.current + 1.day
      @time_window_start = 9  # 9:00
      @time_window_end = 12   # 12:00
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找符合时间窗口的航班
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(:departure_time)
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      raise "未找到符合条件的航班" if @available_flights.empty?
      
      # 选择时间窗口内最便宜的航班作为示例
      @sample_flight = @available_flights.min_by(&:price)
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）上午9:00-12:00从#{@departure_city}到#{@arrival_city}的航班，乘客：#{@expected_passenger_name}。",
        scenario: "#{@expected_passenger_name}明天需要从#{@departure_city}出差到#{@arrival_city}，希望在上午出发（9:00-12:00）",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.strftime('%Y年%m月%d日'),
          time_window: '09:00-12:00（上午时段）',
          passenger: @expected_passenger_name,
          purpose: '商务出行'
        },
        available_flights_sample: {
          count: @available_flights.count,
          example: "#{@sample_flight.flight_number}（#{@sample_flight.departure_time.strftime('%H:%M')}起飞，#{@sample_flight.price}元）"
        },
        hint: "选择上午时段的航班，起飞时间必须在9:00-12:00之间。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      # 断言2: 航班路线正确（深圳→北京） (15%)
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.flight.departure_city}"
        expect(@booking.flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.flight.destination_city}"
      end
      
      # 断言3: 起飞日期正确（明天） (15%)
      add_assertion "起飞日期正确（明天#{@flight_date}）", weight: 15 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（明天）, 实际: #{@booking.flight.flight_date}"
      end
      
      # 断言4: 起飞时间在9:00-12:00窗口内 (30%)
      add_assertion "起飞时间在9:00-12:00窗口内", weight: 30 do
        hour = @booking.flight.departure_time.hour
        expect(hour).to be >= @time_window_start,
          "起飞时间过早。期望: ≥#{@time_window_start}:00, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}"
        expect(hour).to be < @time_window_end,
          "起飞时间过晚。期望: <#{@time_window_end}:00, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      # 断言5: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言6: 订单状态有效 (10%)
      add_assertion "订单状态有效", weight: 10 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合时间窗口的航班（优先选择价格低的）
      flight = @available_flights.min_by(&:price)
      
      # 使用 prepare 中预查询的乘客数据
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s,
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
      @flight_date = Date.parse(data['flight_date'])
      @time_window_start = data['time_window_start']
      @time_window_end = data['time_window_end']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 恢复可用航班列表
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(:departure_time)
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      @sample_flight = @available_flights.min_by(&:price) if @available_flights.any?
    end
  end
end
