# frozen_string_literal: true

require_relative '../base_validator'

# V249: 预订含餐食服务的航班
#
# 任务描述:
#   用户需要预订包含餐食服务的航班
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 航班提供餐食服务 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V249BookFlightWithMealValidator < BaseValidator
    self.validator_id = 'v249_book_flight_with_meal_validator'
    self.task_id = '4ff4afff-5f5f-5f7f-7f8f-6f9a0b1c2d3f'
    self.title = '预订4天后含餐食服务的航班'
    self.description = '用户需要预订包含餐食服务的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '深圳'
      @flight_date = Date.current + 4.days
      
      # 查找提供餐食的航班（meal_service不为空或包含"餐食"/"meal"）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("meal_service IS NOT NULL AND meal_service != '' OR meal_service LIKE ?", "%餐%").to_a
      
      raise "未找到提供餐食的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（4天后）从#{@departure_city}到#{@destination_city}的航班，要求提供餐食服务。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          meal_service: '必须提供餐食',
          purpose: '用餐需求'
        },
        hint: "选择提供餐食服务的航班。"
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
      
      add_assertion "航班提供餐食服务", weight: 40 do
        flight = @flight_booking.flight
        has_meal = flight.meal_service.present? && flight.meal_service != '无' &&
                   (flight.meal_service.include?('餐') || flight.meal_service.downcase.include?('meal'))
        
        expect(has_meal).to eq(true),
          "航班不提供餐食服务。航班号: #{flight.flight_number}, 餐食服务: #{flight.meal_service}"
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
      
      # 选择第一个提供餐食的航班
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
      ).where("meal_service IS NOT NULL AND meal_service != '' OR meal_service LIKE ?", "%餐%").to_a
    end
  end
end
