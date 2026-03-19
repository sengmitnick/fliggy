# frozen_string_literal: true

require_relative '../base_validator'

# V256: 张三后天要从北京去上海，需要预订红眼航班(23:00-次日02:00)节省费用
#
# 任务描述:
#   张三计划后天从北京飞往上海，为了节省费用，需要预订深夜或凌晨时段的红眼航班。
#   红眼航班通常价格较低，起飞时间在23:00-次日02:00之间，适合预算有限的出行。
#
# 业务流程:
#   1. 用户输入：出发城市（北京）、目的地（上海）、出发日期（后天）、需求（红眼航班省钱）
#   2. 系统筛选：显示后天出发、起飞时间在23:00-次日02:00的红眼航班
#   3. 用户选择：对比红眼时段航班的价格和时间，选择最实惠的航班
#   4. 填写信息：乘客姓名（张三）、身份证号、联系电话
#   5. 确认支付：核对航班信息（红眼时段）、出发日期、总价格
#   6. 完成订单：生成订单，获取红眼航班凭证
#
# 复杂度分析:
#   1. **时间段筛选**（中）：需识别红眼航班的时间范围（23:00-次日02:00），包含跨日逻辑
#   2. **航班筛选逻辑**（中）：过滤符合红眼时段的航班，排除常规时段航班
#   3. **价格优化决策**（低）：在红眼航班中选择价格最低的，实现省钱目标
#   4. **订单信息填写**（低）：标准的乘客信息录入流程
#   5. **时间验证**（中）：确认订单航班起飞时间确实在红眼时段（23:00-02:00），支持跨日判断
#
# 评分标准（总分100%）:
#   - 创建了航班订单 (20%) - 基础操作
#   - 航班路线正确（北京→上海） (15%) - 城市匹配
#   - 起飞日期正确（后天） (10%) - 日期准确性
#   - 起飞时间在23:00-次日02:00红眼时段 (30%) - 核心要求（最高权重，省钱关键）
#   - 乘客信息正确（张三） (10%) - 信息完整性
#   - 订单状态有效 (15%) - 订单可用性
module V251V300
  class V256BookRedEyeFlightCrossDayValidator < BaseValidator
    self.validator_id = 'v256_book_red_eye_flight_cross_day_validator'
    self.task_id = '4d5576f9-5f5f-4e9b-bf8f-9f1a2b3c4d5f'
    self.title = '张三后天要从北京去上海，需要预订红眼航班(23:00-次日02:00)节省费用'
    self.description = '张三后天要从北京去上海，需要预订23:00-次日02:00的红眼航班以节省费用'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 2.days
      
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone
      
      # 红眼航班: 23:00-次日02:00
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        # 23:00-23:59 或 00:00-02:00
        (hour >= 23) || (hour < 2)
      end
      
      raise "未找到符合条件的红眼航班" if @available_flights.empty?
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。#{self.class.title}",
        description: self.class.description,
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          passenger_name: '张三',
          time_window: '23:00-次日02:00（红眼时段）',
          purpose: '节省费用，选择红眼航班'
        },
        hint: "红眼航班通常价格较低，起飞时间在深夜23:00-次日凌晨02:00之间。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @booking = all_bookings.first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
      end
      
      return if @booking.nil?
      
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@booking.flight.departure_city}"
        expect(@booking.flight.destination_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@booking.flight.destination_city}"
      end
      
      add_assertion "起飞日期正确（后天#{@flight_date}）", weight: 10 do
        expect(@booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}（后天）, 实际: #{@booking.flight.flight_date}"
      end
      
      add_assertion "起飞时间在23:00-次日02:00红眼时段（核心要求，省钱关键）", weight: 30 do
        hour = @booking.flight.departure_time.hour
        is_red_eye = (hour >= 23) || (hour < 2)
        expect(is_red_eye).to eq(true),
          "非红眼航班时段，无法实现省钱目标。期望: 23:00-次日02:00（深夜或凌晨）, 实际: #{@booking.flight.departure_time.strftime('%H:%M')}（航班号: #{@booking.flight.flight_number}）"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客证件号错误。期望: #{@expected_passenger_id}, 实际: #{@booking.passenger_id_number}"
        
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合红眼时段的航班（优先选择价格低的）
      flight = @available_flights.min_by(&:price)
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @zhangsan.name,
        passenger_id_number: @zhangsan.id_number,
        contact_phone: @zhangsan.phone,
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
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      all_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      )
      
      @available_flights = all_flights.select do |f|
        hour = f.departure_time.hour
        (hour >= 23) || (hour < 2)
      end
    end
  end
end
