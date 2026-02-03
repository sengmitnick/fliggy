# frozen_string_literal: true

require_relative '../base_validator'

# V207: 预订短途航班（飞行时长≤2小时）
#
# 任务描述:
#   用户需要预订后天深圳→上海航班，飞行时长≤2小时
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航班路线正确（深圳→上海） (15%)
#   - 出发日期正确（后天） (15%)
#   - 飞行时长≤2小时 (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V207BookShortHaulFlightUnder2hValidator < BaseValidator
    self.validator_id = 'v207_book_short_haul_flight_under_2h_validator'
    self.task_id = '6f7798f1-7f7f-4f0d-df0f-1f3a4b5c6d7f'
    self.title = '预订短途航班（飞行时长≤2小时）'
    self.description = '用户需要预订后天深圳→上海航班，飞行时长≤2小时'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @arrival_city = '上海'
      @flight_date = Date.today + 2.days
      @max_duration_minutes = 120  # 2小时 = 120分钟
      
      # 查找符合时长要求的航班
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        f.duration_minutes <= @max_duration_minutes
      end
      
      raise "未找到符合条件的短途航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班，要求飞行时长≤2小时，适合快速出行。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          max_duration: '2小时',
          purpose: '快速短途'
        },
        hint: "选择飞行时长在2小时以内的航班。"
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
      
      add_assertion "出发日期正确（后天#{@flight_date}）", weight: 15 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（后天）, 实际: #{@booking.flight.flight_date}"
      end
      
      add_assertion "飞行时长≤2小时", weight: 30 do
        duration = @booking.flight.duration_minutes
        expect(duration).to be <= @max_duration_minutes,
          "飞行时长超出要求。期望: ≤#{@max_duration_minutes}分钟（2小时）, 实际: #{duration}分钟"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合时长要求的航班（优先选择时长最短的）
      flight = @available_flights.min_by(&:duration_minutes)
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
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
        max_duration_minutes: @max_duration_minutes
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @max_duration_minutes = data['max_duration_minutes']
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        f.duration_minutes <= @max_duration_minutes
      end
    end
  end
end
