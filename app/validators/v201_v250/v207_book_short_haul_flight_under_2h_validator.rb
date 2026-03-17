# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例207: 给张三预订后天短途航班（飞行时长≤2小时，深圳→上海）
#
# 任务描述:
#   张三后天需要从深圳到上海，要求预订飞行时长≤2小时的短途航班。
#   Agent需要理解短途航班的定义，筛选符合时长要求的航班并完成预订。
#
# 业务流程:
#   1. 搜索深圳→上海航班（后天）
#   2. 筛选飞行时长≤2小时的短途航班
#   3. 从符合时长要求的航班中选择一个
#   4. 填写乘客信息（张三）
#   5. 确认订单
#
# 复杂度分析:
#   1. 需要理解短途航班的定义（飞行时长≤2小时）
#   2. 需要根据飞行时长筛选航班
#   3. 需要正确填写乘客信息
#   4. 需要理解"后天"的时间概念
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 航班路线正确（深圳→上海） (15分)
#   - 飞行时长≤2小时 (45分)
#   - 乘客信息正确 (10分)
#   - 订单状态有效 (10分)
module V201V250
  class V207BookShortHaulFlightUnder2hValidator < BaseValidator
    self.validator_id = 'v207_book_short_haul_flight_under_2h_validator'
    self.task_id = '6f7798f1-7f7f-4f0d-df0f-1f3a4b5c6d7f'
    self.title = '给张三预订后天短途航班（飞行时长≤2小时，深圳→上海）'
    self.description = '张三需要预订后天从深圳到上海的航班，要求飞行时长≤2小时'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @arrival_city = '上海'
      @max_duration_minutes = 120  # 2小时 = 120分钟
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找符合时长要求的航班（不限定日期）
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        f.duration_minutes <= @max_duration_minutes
      end
      
      raise "未找到符合条件的短途航班" if @available_flights.empty?
      
      @flight_date = @available_flights.first.flight_date
      @sample_flight = @available_flights.min_by(&:duration_minutes)
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班，要求飞行时长≤2小时，适合快速出行。",
        scenario: "#{@expected_passenger_name}后天需要从#{@departure_city}到#{@arrival_city}，选择短途航班（≤2小时）以节省时间",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          max_duration: '2小时',
          passenger: @expected_passenger_name,
          purpose: '快速短途'
        },
        available_flights_sample: {
          count: @available_flights.count,
          example: "#{@sample_flight.flight_number}（#{@sample_flight.duration_minutes}分钟，#{@sample_flight.price}元）"
        },
        hint: "选择飞行时长在2小时以内的航班。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      # 断言2: 航班路线正确（深圳→上海） (15%)
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.flight.departure_city}"
        expect(@booking.flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.flight.destination_city}"
      end
      
      # 断言3: 飞行时长≤2小时 (45%)
      add_assertion "飞行时长≤2小时", weight: 45 do
        duration = @booking.flight.duration_minutes
        expect(duration).to be <= @max_duration_minutes,
          "飞行时长超出要求。期望: ≤#{@max_duration_minutes}分钟（2小时）, 实际: #{duration}分钟"
      end
      
      # 断言4: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言5: 订单状态有效 (10%)
      add_assertion "订单状态有效", weight: 10 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合时长要求的航班（优先选择时长最短的）
      flight = @available_flights.min_by(&:duration_minutes)
      
      # 使用 prepare 中预查询的乘客数据
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
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s,
        max_duration_minutes: @max_duration_minutes,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @max_duration_minutes = data['max_duration_minutes']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        f.duration_minutes <= @max_duration_minutes
      end
      
      @sample_flight = @available_flights.min_by(&:duration_minutes) if @available_flights.any?
    end
  end
end
