# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例244: 张三后天要从深圳去北京参加重要会议，时间紧张，需要预订直飞航班避免转机延误
#
# 任务描述:
#   张三后天需要从深圳飞往北京参加重要会议，时间紧张，要求预订直飞航班避免转机延误。
#   Agent需要在深圳→北京航线搜索直飞航班（is_direct=true或stops=0），创建1个航班订单，确保出发日期为后天，乘客为张三。
#
# 业务流程（6个关键步骤）：
#   1. 明确乘客信息（张三，使用其姓名、身份证号、电话作为订单信息）
#   2. 搜索深圳→北京航线的航班
#   3. 筛选直飞航班（is_direct=true或stops=0）
#   4. 按价格升序排序，优先选择性价比高的航班
#   5. 确认出发日期（后天=Date.current+2.days）
#   6. 创建航班订单（出发日期=后天，直飞航班）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解直飞航班需求，明确无转机要求（is_direct=true或stops=0）
#   2. 需要准确计算出发日期（后天=Date.current+2.days）
#   3. 需要过滤航班类型，只选择直飞航班
#   4. 需要使用张三的个人信息作为乘客信息（姓名、身份证号、联系电话）
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能预订需要转机的航班，必须是直飞
#
# 评分标准（6项，总计100分）：
#   1. 创建了航班订单（20分）
#   2. 航线正确（深圳→北京）（15分）
#   3. 航班为直飞（无转机）（30分）- 核心业务逻辑
#   4. 出发日期正确（后天）（15分）
#   5. 乘客信息正确（张三的姓名、身份证号）（10分）
#   6. 订单状态有效（10分）
#
# 使用方法:
#   rake validator:simulate_single[v244_book_direct_flight_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V244BookDirectFlightValidator < BaseValidator
    self.validator_id = 'v244_book_direct_flight_validator'
    self.task_id = '9ff95aff-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '张三后天要从深圳去北京参加重要会议，时间紧张，需要预订直飞航班避免转机延误'
    self.description = '张三后天要从深圳去北京参加重要会议，时间紧张，需要预订直飞航班避免转机延误'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '北京'
      @flight_date = Date.current + 2.days
      @flight_type = '直飞'
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      # 筛选直飞航班（is_direct=true或stops=0）
      @available_flights = all_flights.select { |f| f.is_direct || (f.respond_to?(:stops) && f.stops == 0) }
                                      .sort_by(&:price)
      
      raise "未找到#{@flight_date}从#{@departure_city}到#{@destination_city}的直飞航班" if @available_flights.empty?
      
      {
        task: "请为张三预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的#{@flight_type}航班。张三要参加重要会议，时间紧张，需要避免转机延误。",
        requirements: {
          passenger: '张三',
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date.to_s,
          flight_type: @flight_type,
          purpose: '参加重要会议，避免转机延误'
        },
        hint: "在#{@departure_city}→#{@destination_city}航线搜索航班，筛选#{@flight_type}航班（无转机），优先选择性价比高的航班。",
        statistics: {
          total_flights: all_flights.count,
          direct_flights: @available_flights.count,
          price_range: {
            min: @available_flights.map(&:price).min,
            max: @available_flights.map(&:price).max
          },
          cheapest_flight: @available_flights.first&.flight_number,
          flight_numbers: @available_flights.first(3).map(&:flight_number).join(', ')
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
      
      add_assertion "航班为#{@flight_type}（无转机）（核心要求）", weight: 30 do
        flight = @flight_booking.flight
        is_direct = flight.is_direct || (flight.respond_to?(:stops) && flight.stops == 0)
        
        expect(is_direct).to eq(true),
          "航班类型不符合要求。要求: #{@flight_type}（避免转机延误），实际: #{is_direct ? '直飞' : '需转机'}（航班号: #{flight.flight_number}, 转机次数: #{flight.respond_to?(:stops) ? flight.stops : '未知'}）"
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
      
      # 选择最便宜的直飞航班（优先性价比）
      flight = @available_flights.first
      
      raise "未找到从#{@departure_city}到#{@destination_city}的可用直飞航班" if flight.nil?
      
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
        flight_type: @flight_type,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @flight_type = data['flight_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      # 筛选直飞航班（is_direct=true或stops=0）
      @available_flights = all_flights.select { |f| f.is_direct || (f.respond_to?(:stops) && f.stops == 0) }
                                      .sort_by(&:price)
    end
  end
end
