# frozen_string_literal: true

require_relative '../base_validator'

# V244: 预订直飞航班（不转机）
#
# 任务描述:
#   用户需要预订直飞航班（不转机）
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 航班为直飞（无转机） (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V244BookDirectFlightValidator < BaseValidator
    self.validator_id = 'v244_book_direct_flight_validator'
    self.task_id = '9ff95aff-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '预订后天直飞航班（不转机）'
    self.description = '用户需要预订直飞航班（不转机）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '北京'
      @flight_date = Date.current + 2.days
      
      # 查找直飞航班（is_direct=true或stops=0）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("is_direct = ? OR stops = 0", true).to_a
      
      raise "未找到直飞航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的直飞航班（不转机）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          flight_type: '直飞',
          purpose: '避免转机'
        },
        hint: "选择直飞航班，不需要转机。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 40 do
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
      
      add_assertion "航班为直飞（无转机）", weight: 40 do
        flight = @flight_booking.flight
        is_direct = flight.is_direct || (flight.respond_to?(:stops) && flight.stops == 0)
        
        expect(is_direct).to eq(true),
          "航班不是直飞。航班号: #{flight.flight_number}, 是否直飞: #{flight.is_direct}"
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
      
      # 选择第一个直飞航班
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
        flight_date: @flight_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("is_direct = ? OR stops = 0", true).to_a
    end
  end
end
