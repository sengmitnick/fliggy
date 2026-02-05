# frozen_string_literal: true

require_relative '../base_validator'

# V256: 预订红眼航班（跨日）
#
# 任务描述:
#   用户需要预订后天23:00-次日02:00北京→上海红眼航班
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航班路线正确（北京→上海） (15%)
#   - 出发日期正确（后天） (15%)
#   - 起飞时间在23:00-次日02:00红眼时段 (30%)
#   - 订单状态有效 (20%)
module V251V300
  class V256BookRedEyeFlightCrossDayValidator < BaseValidator
    self.validator_id = 'v256_book_red_eye_flight_cross_day_validator'
    self.task_id = '4d5576f9-5f5f-4e9b-bf8f-9f1a2b3c4d5f'
    self.title = '预订红眼航班（跨日）'
    self.description = '用户需要预订后天23:00-次日02:00北京→上海红眼航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 2.days
      
      # 红眼航班: 23:00-次日02:00
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        # 23:00-23:59 或 00:00-02:00
        (hour >= 23) || (hour < 2)
      end
      
      raise "未找到符合条件的红眼航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）晚上23:00-次日凌晨02:00从#{@departure_city}到#{@arrival_city}的红眼航班，价格实惠适合省钱。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          time_window: '23:00-次日02:00',
          purpose: '红眼航班省钱'
        },
        hint: "选择深夜或凌晨时段的航班，起飞时间在23:00-次日02:00之间。"
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
      
      add_assertion "起飞日期正确（后天#{@flight_date}）", weight: 15 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（后天）, 实际: #{@booking.flight.flight_date}"
      end
      
      add_assertion "起飞时间在23:00-次日02:00红眼时段", weight: 30 do
        hour = @booking.flight.departure_time.hour
        is_red_eye = (hour >= 23) || (hour < 2)
        expect(is_red_eye).to eq(true),
          "非红眼航班时段。期望: 23:00-次日02:00, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合红眼时段的航班（优先选择价格低的）
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
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        (hour >= 23) || (hour < 2)
      end
    end
  end
end
