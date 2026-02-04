# frozen_string_literal: true

require_relative '../base_validator'

# V247: 预订可改签的机票
#
# 任务描述:
#   用户需要预订支持改签的机票
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 机票支持改签 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V247BookRebookableFlightValidator < BaseValidator
    self.validator_id = 'v247_book_rebookable_flight_validator'
    self.task_id = '2ff28dff-3f3f-3f5f-5f6f-4f7a8b9c0d1f'
    self.title = '预订可改签的机票'
    self.description = '用户需要预订支持改签的机票'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '杭州'
      @flight_date = Date.today + 5.days
      
      # 查找支持改签的航班（refund_policy包含"改签"或"rebookable"）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("refund_policy LIKE ? OR refund_policy LIKE ?", "%改签%", "%rebookable%").to_a
      
      raise "未找到支持改签的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（5天后）从#{@departure_city}到#{@destination_city}的航班，要求支持改签。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          rebookable: '必须支持改签',
          purpose: '行程灵活'
        },
        hint: "选择退改政策中包含'改签'的机票。"
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
      
      add_assertion "机票支持改签", weight: 40 do
        flight = @flight_booking.flight
        is_rebookable = flight.refund_policy&.include?('改签') || 
                        flight.refund_policy&.downcase&.include?('rebookable')
        
        expect(is_rebookable).to eq(true),
          "机票不支持改签。航班号: #{flight.flight_number}, 退改政策: #{flight.refund_policy}"
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
      
      # 选择第一个支持改签的航班
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
      ).where("refund_policy LIKE ? OR refund_policy LIKE ?", "%改签%", "%rebookable%").to_a
    end
  end
end
