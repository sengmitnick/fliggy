# frozen_string_literal: true

require_relative '../base_validator'

# V246: 预订含托运行李额度的机票
#
# 任务描述:
#   用户需要预订包含托运行李额度的机票
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 机票包含托运行李额度 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V246BookFlightWithBaggageValidator < BaseValidator
    self.validator_id = 'v246_book_flight_with_baggage_validator'
    self.task_id = '1ff17cff-2f2f-2f4f-4f5f-3f6a7b8c9d0f'
    self.title = '预订含托运行李额度的机票'
    self.description = '用户需要预订包含托运行李额度的机票'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '成都'
      @flight_date = Date.today + 3.days
      
      # 查找包含行李额度的航班（baggage_allowance不为空或>0）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("baggage_allowance IS NOT NULL AND baggage_allowance != ''").to_a
      
      raise "未找到包含行李额度的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@destination_city}的航班，要求包含托运行李额度。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          baggage: '必须包含托运行李额度',
          purpose: '携带行李'
        },
        hint: "选择包含托运行李额度的机票。"
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
      
      add_assertion "机票包含托运行李额度", weight: 40 do
        flight = @flight_booking.flight
        has_baggage = flight.baggage_allowance.present? && flight.baggage_allowance != '0'
        
        expect(has_baggage).to eq(true),
          "机票不包含托运行李额度。航班号: #{flight.flight_number}, 行李额度: #{flight.baggage_allowance}"
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
      
      # 选择第一个包含行李额度的航班
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
      ).where("baggage_allowance IS NOT NULL AND baggage_allowance != ''").to_a
    end
  end
end
