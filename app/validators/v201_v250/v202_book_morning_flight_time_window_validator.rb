# frozen_string_literal: true

require_relative '../base_validator'

# V202: 预订上午航班（时间窗口）
#
# 任务描述:
#   用户需要预订明天9:00-12:00深圳→北京的航班（商务出行）
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航班路线正确（深圳→北京） (15%)
#   - 起飞日期正确（明天） (15%)
#   - 起飞时间在9:00-12:00窗口内 (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V202BookMorningFlightTimeWindowValidator < BaseValidator
    self.validator_id = 'v202_book_morning_flight_time_window_validator'
    self.task_id = 'eab7dcf4-8b17-4de8-9f8b-98eaa110ac1f'
    self.title = '预订上午航班（时间窗口）'
    self.description = '用户需要预订明天9:00-12:00深圳→北京的航班（商务出行）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @arrival_city = '北京'
      @flight_date = Date.today + 1.day
      @time_window_start = 9  # 9:00
      @time_window_end = 12   # 12:00
      
      # 查找符合时间窗口的航班
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      raise "未找到符合条件的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）上午9:00-12:00从#{@departure_city}到#{@arrival_city}的航班，适合商务出行。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          time_window: '09:00-12:00',
          purpose: '商务出行'
        },
        hint: "选择上午时段的航班，起飞时间在9:00-12:00之间。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @booking = all_bookings.first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
      end
      
      return if @booking.nil?
      
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.flight.departure_city}"
        expect(@booking.flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.flight.destination_city}"
      end
      
      add_assertion "起飞日期正确（明天#{@flight_date}）", weight: 15 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（明天）, 实际: #{@booking.flight.flight_date}"
      end
      
      add_assertion "起飞时间在9:00-12:00窗口内", weight: 30 do
        hour = @booking.flight.departure_time.hour
        expect(hour).to be >= @time_window_start,
          "起飞时间过早。期望: ≥#{@time_window_start}:00, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}"
        expect(hour).to be < @time_window_end,
          "起飞时间过晚。期望: <#{@time_window_end}:00, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合时间窗口的航班（优先选择价格低的）
      flight = @available_flights.min_by(&:price)
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        accept_terms: true,
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
        flight_date: @flight_date.to_s,
        time_window_start: @time_window_start,
        time_window_end: @time_window_end
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @time_window_start = data['time_window_start']
      @time_window_end = data['time_window_end']
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        hour >= @time_window_start && hour < @time_window_end
      end
    end
  end
end
