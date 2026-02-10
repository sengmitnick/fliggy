# frozen_string_literal: true

require_relative '../base_validator'

# V245: 预订宽体机航班（长途舒适）
#
# 任务描述:
#   用户需要预订宽体机航班（长途飞行更舒适）
#
# 评分标准:
#   - 创建了航班订单 (55%)
#   - 航班为宽体机 (40%)
#   - 订单状态有效 (5%)
module V201V250
  class V245BookWidebodyAircraftValidator < BaseValidator
    self.validator_id = 'v245_book_widebody_aircraft_validator'
    self.task_id = '0ff06bff-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '给张三预订宽体机航班（去洛杉矶，长途舒适）'
    self.description = '张三要从北京飞洛杉矶长途飞行，需要预订宽体机航班（如波音777、787）保证舒适度'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '洛杉矶'
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_user.passenger_name,
        id_number: demo_user.passenger_id_number,
        phone: demo_user.passenger_phone
      )
      
      # 查找宽体机航班（aircraft_type包含"宽体"或常见宽体机型）
      widebody_types = ['波音777', '波音787', '空客A330', '空客A350', '空客A380', '宽体']
      conditions = widebody_types.map { "aircraft_type LIKE ?" }.join(' OR ')
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where(conditions, *widebody_types.map { |t| "%#{t}%" }).to_a
      
      raise "未找到宽体机航班" if @available_flights.empty?
      
      # 使用实际航班日期
      @flight_date = @available_flights.first.flight_date
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的宽体机航班（长途飞行更舒适）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          aircraft_type: '宽体机',
          purpose: '长途舒适'
        },
        hint: "选择宽体机型（如波音777、787、空客A330等）。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 55 do
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
      
      add_assertion "航班为宽体机", weight: 40 do
        flight = @flight_booking.flight
        widebody_keywords = ['波音777', '波音787', '空客A330', '空客A350', '空客A380', '宽体', 'widebody']
        is_widebody = widebody_keywords.any? { |keyword| flight.aircraft_type&.include?(keyword) }
        
        expect(is_widebody).to eq(true),
          "航班不是宽体机。机型: #{flight.aircraft_type}, 航班号: #{flight.flight_number}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一个宽体机航班
      flight = @available_flights.first
      
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
        destination_city: @destination_city,
        flight_date: @flight_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      
      widebody_types = ['波音777', '波音787', '空客A330', '空客A350', '空客A380', '宽体']
      conditions = widebody_types.map { "aircraft_type LIKE ?" }.join(' OR ')
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where(conditions, *widebody_types.map { |t| "%#{t}%" }).to_a
    end
  end
end
