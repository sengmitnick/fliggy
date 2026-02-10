# frozen_string_literal: true

require_relative '../base_validator'

# V245: 预订长途航班（北京到洛杉矶）
#
# 任务描述:
#   用户需要预订从北京到洛杉矶的长途航班
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航线正确（北京→洛杉矶） (15%)
#   - 出发日期正确 (15%)
#   - 机票价格合理 (25%)
#   - 乘客信息正确 (15%)
#   - 订单状态有效 (10%)
module V201V250
  class V245BookWidebodyAircraftValidator < BaseValidator
    self.validator_id = 'v245_book_widebody_aircraft_validator'
    self.task_id = '0ff06bff-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '给张三预订长途航班（去洛杉矶）'
    self.description = '张三要从北京飞洛杉矶，需要预订合适的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '洛杉矶'
      @departure_date = Date.today + 7.days
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找可用航班
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where('flight_date >= ?', @departure_date).to_a
      
      raise "未找到可用航班" if @available_flights.empty?
      
      # 使用实际航班日期
      @flight_date = @available_flights.first.flight_date
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的航班，出发日期#{@departure_date}左右。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          departure_date: @departure_date.to_s,
          passenger_name: '张三'
        },
        hint: "选择合适的航班即可。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到航班订单"
        @flight_booking = all_bookings.first
      end
      
      return if @flight_booking.nil?
      
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@destination_city),
          "目的地城市错误。期望: #{@destination_city}, 实际: #{flight.destination_city}"
      end
      
      add_assertion "出发日期合理（#{@departure_date}左右）", weight: 15 do
        flight = @flight_booking.flight
        date_diff = (flight.flight_date - @departure_date).abs
        expect(date_diff).to be <= 3,
          "出发日期偏差过大。期望: #{@departure_date}±3天, 实际: #{flight.flight_date}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "机票价格合理", weight: 25 do
        flight = @flight_booking.flight
        expect(@flight_booking.total_price).to be > 0,
          "订单总价异常。实际总价: #{@flight_booking.total_price}"
        expect(@flight_booking.total_price).to eq(flight.price),
          "订单总价与航班票价不符。期望: #{flight.price}, 实际: #{@flight_booking.total_price}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 15 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一个可用航班
      flight = @available_flights.first
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
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
        departure_date: @departure_date.to_s,
        flight_date: @flight_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date'])
      @flight_date = Date.parse(data['flight_date'])
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where('flight_date >= ?', @departure_date).to_a
    end
  end
end
