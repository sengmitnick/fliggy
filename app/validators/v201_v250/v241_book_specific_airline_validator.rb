# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例241: 张三后天要从北京去上海出差，公司有协议价，需要预订东方航空的航班
#
# 任务描述:
#   张三后天需要从北京飞往上海出差，公司与东方航空有协议价，要求预订东方航空的航班。
#   Agent需要在北京→上海航线筛选出东方航空的航班，创建1个航班订单，确保出发日期为后天，乘客为张三。
#
# 业务流程（6个关键步骤）：
#   1. 明确乘客信息（张三，使用其姓名、身份证号、电话作为订单信息）
#   2. 搜索北京→上海航线的航班
#   3. 筛选东方航空的航班（airline字段包含'东方航空'）
#   4. 按价格升序排序，优先选择性价比高的航班
#   5. 确认出发日期（后天=Date.current+2.days）
#   6. 创建航班订单（出发日期=后天，航空公司=东方航空）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解指定航空公司预订场景，明确航空公司筛选条件（airline包含'东方航空'）
#   2. 需要准确计算出发日期（后天=Date.current+2.days）
#   3. 需要在指定航空公司的航班中优先选择性价比高的航班（价格排序）
#   4. 需要使用张三的个人信息作为乘客信息（姓名、身份证号、联系电话）
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择其他航空公司的航班，必须严格检查airline字段
#
# 评分标准（6项，总计100分）：
#   1. 创建了航班订单（20分）
#   2. 航线正确（北京→上海）（15分）
#   3. 航空公司符合要求（东方航空）（30分）- 核心业务逻辑
#   4. 出发日期正确（后天）（15分）
#   5. 乘客信息正确（张三的姓名、身份证号）（10分）
#   6. 订单状态有效（10分）
#
# 使用方法:
#   rake validator:simulate_single[v241_book_specific_airline_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
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
      @airline = '东方航空'  # 公司协议价航空公司
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找指定航空公司的航班（airline字段包含'东方航空'）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("airline LIKE ?", "%#{@airline}%")
        .order(price: :asc)
        .to_a
      
      raise "未找到#{@flight_date}从#{@departure_city}到#{@destination_city}的#{@airline}航班" if @available_flights.empty?
      
      {
        task: "请为张三预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的#{@airline}航班。公司与#{@airline}有协议价。",
        requirements: {
          passenger: '张三',
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date.to_s,
          airline: @airline,
          purpose: '公司协议价'
        },
        hint: "在#{@departure_city}→#{@destination_city}航线筛选#{@airline}的航班（airline包含'#{@airline}'），优先选择性价比高的航班。",
        statistics: {
          available_flights: @available_flights.count,
          price_range: {
            min: @available_flights.minimum(:price),
            max: @available_flights.maximum(:price)
          },
          cheapest_flight: @available_flights.first&.flight_number
        }
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
      
      add_assertion "航空公司符合要求（#{@airline}）- 核心要求", weight: 30 do
        flight = @flight_booking.flight
        is_correct_airline = flight.airline&.include?(@airline)
        
        expect(is_correct_airline).to eq(true),
          "航空公司不符合要求。要求: #{@airline}（公司协议价）, 实际: #{flight.airline}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "出发日期正确（#{@flight_date.strftime('%m月%d日')}，后天）", weight: 15 do
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
          "订单状态无效。实际: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最便宜的东方航空航班（公司协议价，优先性价比）
      flight = @available_flights.first
      
      raise "未找到#{@airline}的可用航班" if flight.nil?
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id,
        contact_phone: @expected_contact_phone,
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
        airline: @airline,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @airline = data['airline']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("airline LIKE ?", "%#{@airline}%")
        .order(price: :asc)
        .to_a
    end
  end
end
