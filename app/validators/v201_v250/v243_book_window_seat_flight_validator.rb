# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例243: 张三3天后要从上海去广州，希望预订上午出发的航班
#
# 任务描述:
#   张三3天后需要从上海飞往广州，希望预订上午出发（12点前）的航班，方便到达后有充足时间办事。
#   Agent需要在上海→广州航线搜索航班，筛选上午出发的航班，创建1个航班订单，确保出发日期为3天后，乘客为张三。
#
# 业务流程（6个关键步骤）：
#   1. 明确乘客信息（张三，使用其姓名、身份证号、电话作为订单信息）
#   2. 搜索上海→广州航线的航班
#   3. 筛选上午出发的航班（departure_time.hour < 12）
#   4. 按价格升序排序，优先选择性价比高的航班
#   5. 确认出发日期（3天后=Date.current+3.days）
#   6. 创建航班订单（出发日期=3天后，上午航班）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解时间偏好场景，明确上午航班需求（departure_time.hour < 12）
#   2. 需要准确计算出发日期（3天后=Date.current+3.days）
#   3. 需要过滤航班出发时间，只选择上午航班
#   4. 需要使用张三的个人信息作为乘客信息（姓名、身份证号、联系电话）
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能预订下午或晚上的航班，必须是12点前出发
#
# 评分标准（6项，总计100分）：
#   1. 创建了航班订单（20分）
#   2. 航线正确（上海→广州）（15分）
#   3. 航班出发时间为上午（12点前）（30分）- 核心业务逻辑
#   4. 出发日期正确（3天后）（15分）
#   5. 乘客信息正确（张三的姓名、身份证号）（10分）
#   6. 订单状态有效（10分）
#
# 使用方法:
#   rake validator:simulate_single[v243_book_window_seat_flight_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V243BookWindowSeatFlightValidator < BaseValidator
    self.validator_id = 'v243_book_window_seat_flight_validator'
    self.task_id = '8ff849ff-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '张三3天后要从上海去广州，希望预订上午出发的航班'
    self.description = '张三3天后要从上海去广州，希望预订上午出发的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '广州'
      @flight_date = Date.current + 3.days
      @time_preference = '上午'
      
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
      
      # 筛选上午航班（12点前出发）
      @available_flights = all_flights.select { |f| f.departure_time.hour < 12 }
                                      .sort_by(&:price)
      
      raise "未找到#{@flight_date}从#{@departure_city}到#{@destination_city}的上午航班" if @available_flights.empty?
      
      {
        task: "请为张三预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@destination_city}的航班，要求#{@time_preference}出发（12点前）。张三希望到达后有充足时间办事。",
        requirements: {
          passenger: '张三',
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date.to_s,
          time_preference: @time_preference,
          purpose: '到达后有充足时间办事'
        },
        hint: "在#{@departure_city}→#{@destination_city}航线搜索航班，筛选#{@time_preference}出发（12点前）的航班，优先选择性价比高的航班。",
        statistics: {
          total_flights: all_flights.count,
          morning_flights: @available_flights.count,
          price_range: {
            min: @available_flights.map(&:price).min,
            max: @available_flights.map(&:price).max
          },
          cheapest_flight: @available_flights.first&.flight_number,
          departure_times: @available_flights.first(3).map { |f| f.departure_time.strftime('%H:%M') }.join(', ')
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
      
      add_assertion "航班出发时间为#{@time_preference}（12点前）（核心要求）", weight: 30 do
        flight = @flight_booking.flight
        departure_hour = flight.departure_time.hour
        is_morning = departure_hour < 12
        
        expect(is_morning).to eq(true),
          "出发时间不符合要求。要求: #{@time_preference}出发（12点前），实际: #{flight.departure_time.strftime('%H:%M')}出发（#{departure_hour >= 12 ? '下午' : '上午'}）"
      end
      
      add_assertion "出发日期正确（#{@flight_date.strftime('%m月%d日')}，3天后）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（3天后）, 实际: #{flight.flight_date}"
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
      
      # 选择最便宜的上午航班（优先性价比）
      flight = @available_flights.first
      
      raise "未找到从#{@departure_city}到#{@destination_city}的可用上午航班" if flight.nil?
      
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
        time_preference: @time_preference,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @time_preference = data['time_preference']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      # 筛选上午航班（12点前出发）
      @available_flights = all_flights.select { |f| f.departure_time.hour < 12 }
                                      .sort_by(&:price)
    end
  end
end
