# frozen_string_literal: true

require_relative '../base_validator'

# V250: 预订里程累积航班（常旅客计划）
#
# 任务描述:
#   用户需要预订可累积里程的航班（参与常旅客计划）
#
# 评分标准:
#   - 创建了航班订单 (40%)
#   - 航班支持里程累积 (40%)
#   - 出发日期正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V250BookMileageAccrualFlightValidator < BaseValidator
    self.validator_id = 'v250_book_mileage_accrual_flight_validator'
    self.task_id = '5ff5b0ff-6f6f-6f8f-8f9f-7f0a1b2c3d4f'
    self.title = '预订3天后里程累积航班（常旅客计划）'
    self.description = '用户需要预订可累积里程的航班（参与常旅客计划）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '广州'
      @flight_date = Date.current + 3.days
      
      # 查找支持里程累积的航班（mileage_accrual不为空或航空公司为主流航司）
      major_airlines = ['国航', '东航', '南航', '海航', 'Air China', 'China Eastern', 'China Southern']
      conditions = ["mileage_accrual IS NOT NULL AND mileage_accrual != ''"] + 
                   major_airlines.map { "airline LIKE ?" }
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where(conditions.join(' OR '), *major_airlines.map { |a| "%#{a}%" }).to_a
      
      raise "未找到支持里程累积的航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@destination_city}的航班，要求可累积里程（常旅客计划）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          mileage_accrual: '必须可累积里程',
          purpose: '积累里程'
        },
        hint: "选择主流航空公司或明确支持里程累积的航班。"
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
      
      add_assertion "航班支持里程累积", weight: 40 do
        flight = @flight_booking.flight
        major_airlines = ['国航', '东航', '南航', '海航', 'Air China', 'China Eastern', 'China Southern']
        
        supports_mileage = (flight.mileage_accrual.present? && flight.mileage_accrual != '否' && flight.mileage_accrual != '不可累积') ||
                           major_airlines.any? { |airline| flight.airline&.include?(airline) }
        
        expect(supports_mileage).to eq(true),
          "航班不支持里程累积。航空公司: #{flight.airline}, 里程累积: #{flight.mileage_accrual}"
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
      
      # 优先选择明确标注支持里程累积的航班（mileage_accrual='可累积里程' 或类似值）
      flight = @available_flights.find { |f| f.mileage_accrual.present? && (f.mileage_accrual.start_with?('可累积') || f.mileage_accrual == '可累积里程') } ||
               @available_flights.find { |f| f.mileage_accrual.present? && f.mileage_accrual != '否' && f.mileage_accrual != '不可累积' && !f.mileage_accrual.include?('不可') } ||
               @available_flights.first
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        frequent_flyer_number: 'FF123456789',  # 常旅客号码
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
      
      major_airlines = ['国航', '东航', '南航', '海航', 'Air China', 'China Eastern', 'China Southern']
      conditions = ["mileage_accrual IS NOT NULL AND mileage_accrual != ''"] + 
                   major_airlines.map { "airline LIKE ?" }
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where(conditions.join(' OR '), *major_airlines.map { |a| "%#{a}%" }).to_a
    end
  end
end
