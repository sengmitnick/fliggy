# frozen_string_literal: true

require_relative '../base_validator'

# V241: 预订特定航空公司航班
#
# 任务描述:
#   用户需要预订特定航空公司的航班（如国航、东航）
#
# 评分标准:
#   - 创建了航班订单 (30%)
#   - 航空公司符合要求 (40%)
#   - 出发日期正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V241BookSpecificAirlineValidator < BaseValidator
    self.validator_id = 'v241_book_specific_airline_validator'
    self.task_id = '7ff738ff-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '预订特定航空公司航班'
    self.description = '用户需要预订特定航空公司的航班（如国航、东航）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '上海'
      @flight_date = Date.current + 2.days
      @airline = '东方航空'  # 指定航空公司
      
      # 查找指定航空公司的航班（airline包含关键词）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("airline LIKE ?", "%#{@airline}%").to_a
      
      raise "未找到#{@airline}的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的#{@airline}航班。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          airline: @airline,
          purpose: '指定航空公司'
        },
        hint: "选择#{@airline}的航班。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 30 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_booking = all_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "航空公司符合要求（#{@airline}）", weight: 40 do
        flight = @flight_booking.flight
        is_correct_airline = flight.airline&.include?(@airline)
        
        expect(is_correct_airline).to eq(true),
          "航空公司不符合要求。要求: #{@airline}, 实际: #{flight.airline}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "出发日期正确", weight: 20 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}, 实际: #{flight.flight_date}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一个符合航空公司要求的航班
      flight = @available_flights.first
      
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
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        airline: @airline
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @airline = data['airline']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("airline LIKE ?", "%#{@airline}%").to_a
    end
  end
end
