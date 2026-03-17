# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例205: 给张三预订后天红眼航班（23:00-次日02:00，北京→上海）
#
# 任务描述:
#   张三后天需要从北京到上海，要求预订深夜23:00到次日凌晨02:00的红眼航班。
#   Agent需要理解红眼航班的时间特点（跨日），筛选符合时间要求的航班并完成预订。
#
# 业务流程:
#   1. 搜索北京→上海航班（后天晚上+次日凌晨）
#   2. 筛选23:00-23:59（当天）或00:00-02:00（次日）的航班
#   3. 从符合红眼航班时间的航班中选择一个
#   4. 填写乘客信息（张三）
#   5. 确认订单
#
# 复杂度分析:
#   1. 需要理解红眼航班的定义（23:00-次日02:00深夜航班）
#   2. 需要处理跨日查询（当天23点后+次日2点前）
#   3. 需要在两个日期范围内筛选航班
#   4. 需要正确填写乘客信息
#   5. 需要理解"后天"的时间概念
#
# 评分标准:
#   - 创建了航班订单 (25分)
#   - 航班是红眼航班（23:00-次日02:00） (40分)
#   - 乘客信息正确（张三） (10分)
#   - 订单状态有效 (25分)
module V201V250
  class V205BookMidnightFlightRedEyeValidator < BaseValidator
    self.validator_id = 'v205_book_midnight_flight_red_eye_validator'
    self.task_id = '8c9d0e1f-2a3b-4c5d-6e7f-8a9b0c1d2e3f'
    self.title = '给张三预订后天红眼航班（23:00-次日02:00，北京→上海）'
    self.description = '张三需要预订后天晚上23:00到次日凌晨02:00的深夜航班，从北京到上海'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 2.days
      @next_day_date = @flight_date + 1.day
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找23:00-23:59的航班（当天）
      late_night_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= 23 }
      
      # 查找00:00-02:00的航班（次日）
      early_morning_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @next_day_date,
        data_version: 0
      ).select { |f| f.departure_time.hour < 2 }
      
      @available_flights = (late_night_flights + early_morning_flights).sort_by(&:departure_time)
      
      raise "未找到符合条件的红眼航班" if @available_flights.empty?
      
      # 选择最便宜的红眼航班作为示例
      @sample_flight = @available_flights.min_by(&:price)
      
      {
        task: "请预订后天（#{@flight_date.strftime('%Y年%m月%d日')}）晚上23:00到次日凌晨02:00从#{@departure_city}到#{@arrival_city}的红眼航班，乘客：#{@expected_passenger_name}。",
        scenario: "#{@expected_passenger_name}后天需要从#{@departure_city}到#{@arrival_city}，选择深夜红眼航班（23:00-次日02:00）以节省时间和费用",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.strftime('%Y年%m月%d日'),
          time_range: '23:00-次日02:00（红眼航班）',
          passenger: @expected_passenger_name,
          type: '深夜航班'
        },
        available_flights_sample: {
          count: @available_flights.count,
          example: "#{@sample_flight.flight_number}（#{@sample_flight.departure_time.strftime('%Y-%m-%d %H:%M')}起飞，#{@sample_flight.price}元）"
        },
        hint: "红眼航班是指深夜起飞的航班（23:00-次日02:00），通常价格较低但需要休息设施。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (25%)
      add_assertion "创建了航班订单", weight: 25 do
        # 查询两天的航班订单（因为红眼航班可能跨天）
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(flights: { flight_date: [@flight_date, @next_day_date] })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      # 断言2: 航班是红眼航班（23:00-次日02:00） (40%)
      add_assertion "航班是红眼航班（23:00-次日02:00）", weight: 40 do
        hour = @booking.flight.departure_time.hour
        flight_date = @booking.flight.flight_date
        
        # 检查是否为23:00-23:59（当天）或00:00-02:00（次日）
        is_red_eye = (flight_date == @flight_date && hour >= 23) ||
                      (flight_date == @next_day_date && hour < 2)
        
        expect(is_red_eye).to eq(true),
          "不是红眼航班。起飞时间: #{@booking.flight.departure_time.strftime('%Y-%m-%d %H:%M')}，期望: #{@flight_date} 23:00 到 #{@next_day_date} 02:00"
      end
      
      # 断言3: 乘客信息正确（张三） (10%)
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      # 断言4: 订单状态有效 (25%)
      add_assertion "订单状态有效", weight: 25 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格最低的红眼航班
      flight = @available_flights.min_by(&:price)
      
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
        next_day_date: @next_day_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @next_day_date = Date.parse(data['next_day_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 恢复可用航班列表
      late_night_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= 23 }
      
      early_morning_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @next_day_date,
        data_version: 0
      ).select { |f| f.departure_time.hour < 2 }
      
      @available_flights = (late_night_flights + early_morning_flights).sort_by(&:departure_time)
      
      @sample_flight = @available_flights.min_by(&:price) if @available_flights.any?
    end
  end
end
