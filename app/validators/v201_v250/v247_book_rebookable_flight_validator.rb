# frozen_string_literal: true

require_relative '../base_validator'

# V247: 预订可改签航班
#
# 任务描述:
#   用户需要预订可改签的航班（行程灵活）
#
# 评分标准:
#   - 创建了航班订单 (55%)
#   - 航班可改签 (40%)
#   - 订单状态有效 (5%)
module V201V250
  class V247BookRebookableFlightValidator < BaseValidator
    self.validator_id = 'v247_book_rebookable_flight_validator'
    self.task_id = 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d'
    self.title = '给张三预订可改签航班（去广州，行程可能变动）'
    self.description = '张三要从上海去广州，但行程还没最终确定，需要预订支持改签的航班方便调整时间'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '广州'
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_user.passenger_name,
        id_number: demo_user.passenger_id_number,
        phone: demo_user.passenger_phone
      )
      
      # 查找航班（所有航班都可能允许改签，使用refund_policy判断）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).to_a.select { |f| f.refund_policy&.include?('改签') || f.refund_policy&.include?('退改') }
      
      raise "未找到可改签的航班" if @available_flights.empty?
      
      # 使用实际航班日期
      @flight_date = @available_flights.first.flight_date
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的可改签航班（行程可能有变，需要灵活改签）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          rebookable: true,
          purpose: '行程灵活'
        },
        hint: "选择支持改签的航班。"
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
      
      add_assertion "航班可改签", weight: 40 do
        flight = @flight_booking.flight
        is_rebookable = flight.refund_policy&.include?('改签') || flight.refund_policy&.include?('退改')
        expect(is_rebookable).to eq(true),
          "航班不可改签。航班号: #{flight.flight_number}, 退改政策: #{flight.refund_policy}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一个可改签航班
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
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).to_a.select { |f| f.refund_policy&.include?('改签') || f.refund_policy&.include?('退改') }
    end
  end
end
