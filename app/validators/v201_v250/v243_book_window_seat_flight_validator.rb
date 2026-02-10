# frozen_string_literal: true

require_relative '../base_validator'

# V243: 预订靠窗座位航班
#
# 任务描述:
#   用户需要预订靠窗座位的航班
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 座位类型为靠窗 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V243BookWindowSeatFlightValidator < BaseValidator
    self.validator_id = 'v243_book_window_seat_flight_validator'
    self.task_id = '8ff849ff-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '给张三预订靠窗座位航班（3天后去广州）'
    self.description = '张三3天后要从上海去广州，喜欢看窗外风景，需要预订靠窗座位的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '广州'
      @flight_date = Date.current + 3.days
      @seat_preference = '靠窗'
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_user.passenger_name,
        id_number: demo_user.passenger_id_number,
        phone: demo_user.passenger_phone
      )
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      raise "未找到航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@destination_city}的航班，要求#{@seat_preference}座位。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          seat_preference: @seat_preference,
          purpose: '座位偏好'
        },
        hint: "选择靠窗座位。"
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
      
      add_assertion "座位类型为#{@seat_preference}", weight: 40 do
        # 假设Booking模型有seat_preference字段
        seat_pref = @flight_booking.seat_preference || @flight_booking.notes
        has_window_seat = seat_pref&.include?(@seat_preference) || seat_pref&.include?('window')
        
        expect(has_window_seat).to eq(true),
          "座位类型不符合要求。要求: #{@seat_preference}, 实际: #{seat_pref}"
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
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: flight.price,
        seat_preference: @seat_preference,
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
        seat_preference: @seat_preference
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @seat_preference = data['seat_preference']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
    end
  end
end
