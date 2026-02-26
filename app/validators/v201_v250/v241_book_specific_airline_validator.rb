# frozen_string_literal: true

require_relative '../base_validator'

# V241: 预订特定航空公司航班
#
# 任务描述:
#   用户需要预订特定航空公司的航班（如国航、东航）
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航线正确（北京→上海） (15%)
#   - 航空公司符合要求（东方航空） (30%)
#   - 出发日期正确（后天） (15%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V241BookSpecificAirlineValidator < BaseValidator
    self.validator_id = 'v241_book_specific_airline_validator'
    self.task_id = '7ff738ff-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '张三后天要从北京去上海出差，公司有协议价，需要预订东方航空的航班'
    self.description = '张三后天要从北京去上海出差，公司有协议价，需要预订东方航空的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '上海'
      @flight_date = Date.current + 2.days
      @airline = '东方航空'  # 指定航空公司
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
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
      
      add_assertion "航空公司符合要求（#{@airline}）", weight: 30 do
        flight = @flight_booking.flight
        is_correct_airline = flight.airline&.include?(@airline)
        
        expect(is_correct_airline).to eq(true),
          "航空公司不符合要求。期望: #{@airline}, 实际: #{flight.airline}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "出发日期正确（#{@flight_date}，后天）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（后天）, 实际: #{flight.flight_date}"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 10 do
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
      
      # 选择第一个符合航空公司要求的航班
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
