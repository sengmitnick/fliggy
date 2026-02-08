# frozen_string_literal: true

require_relative '../base_validator'

# V248: 预订特定座位号（如过道座、紧急出口排）
#
# 任务描述:
#   用户需要预订特定座位号或座位位置（如过道座、紧急出口排）
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 座位位置符合要求 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V248BookSpecificSeatNumberValidator < BaseValidator
    self.validator_id = 'v248_book_specific_seat_number_validator'
    self.task_id = '3ff39eff-4f4f-4f6f-6f7f-5f8a9b0c1d2f'
    self.title = '预订后天特定座位号（如过道座）'
    self.description = '用户需要预订特定座位号或座位位置（如过道座、紧急出口排）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '上海'
      @flight_date = Date.current + 2.days
      @seat_type = '过道'  # 或具体座位号
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      raise "未找到航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的航班，要求#{@seat_type}座位。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          seat_type: @seat_type,
          purpose: '座位偏好'
        },
        hint: "选择过道座位（方便进出）。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 40 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_booking = all_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "座位位置符合要求（#{@seat_type}）", weight: 40 do
        seat_info = @flight_booking.seat_preference || @flight_booking.seat_number || @flight_booking.notes
        matches_preference = seat_info&.include?(@seat_type) || 
                             seat_info&.include?('aisle') ||
                             seat_info&.match?(/\d+[CD]/)  # C/D通常是过道座
        
        expect(matches_preference).to eq(true),
          "座位位置不符合要求。要求: #{@seat_type}, 实际: #{seat_info}"
      end
      
      add_assertion "出发日期正确", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}, 实际: #{flight.flight_date}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      flight = @available_flights.first
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        seat_preference: @seat_type,
        seat_number: '12C',  # C通常是过道座
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        seat_type: @seat_type
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @seat_type = data['seat_type']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
    end
  end
end
