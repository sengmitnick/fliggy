# frozen_string_literal: true

require_relative '../base_validator'

# V249: 张三4天后要从上海去深圳，需要预订合适的航班
#
# 任务描述:
#   张三计划4天后从上海飞往深圳，需要预订4天后出发的航班。
#   选择任意可用的航班即可，无特殊要求。
#
# 业务流程:
#   1. 用户输入：出发城市（上海）、目的地（深圳）、出发日期（4天后）
#   2. 系统筛选：显示4天后从上海到深圳的所有可用航班
#   3. 用户选择：对比航班时间和价格，选择合适航班
#   4. 填写信息：乘客姓名（张三）、身份证号、联系电话
#   5. 确认支付：核对航班信息、出发日期、总价格
#   6. 完成订单：生成订单，获取航班凭证
#
# 复杂度分析:
#   1. **日期计算**（低）：计算4天后的日期（Date.current + 4.days）
#   2. **航班筛选逻辑**（低）：按城市和日期过滤航班
#   3. **价格对比决策**（低）：在可用航班中选择合适的
#   4. **订单信息填写**（低）：标准的乘客信息录入流程
#   5. **日期验证**（低）：确认订单航班日期是否为4天后
#
# 评分标准（总分100%）:
#   - 创建了航班订单 (20%) - 基础操作
#   - 航线正确（上海→深圳） (15%) - 城市匹配
#   - 出发日期正确（4天后） (30%) - 日期准确性（最高权重）
#   - 机票价格合理 (15%) - 价格有效性
#   - 乘客信息正确（张三） (10%) - 信息完整性
#   - 订单状态有效 (10%) - 订单可用性
module V201V250
  class V249BookFlightWithMealValidator < BaseValidator
    self.validator_id = 'v249_book_flight_with_meal_validator'
    self.task_id = '4ff4afff-5f5f-5f7f-7f8f-6f9a0b1c2d3f'
    self.title = '张三4天后要从上海去深圳，需要预订合适的航班'
    self.description = '张三4天后要从上海去深圳，需要预订合适的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '深圳'
      @flight_date = Date.current + 4.days  # 4天后出发
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找可用航班
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      raise "未找到#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的航班" if @available_flights.empty?
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。#{self.class.title}",
        description: self.class.description,
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          passenger_name: '张三'
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
      
      add_assertion "出发日期正确（#{@flight_date&.strftime('%Y-%m-%d')}，4天后）", weight: 30 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date&.strftime('%Y-%m-%d')}（4天后）, 实际: #{flight.flight_date&.strftime('%Y-%m-%d')}（航班号: #{flight.flight_number}）"
      end
      
      add_assertion "机票价格合理", weight: 15 do
        expect(@flight_booking.total_price).to be > 0,
          "订单总价异常。实际总价: #{@flight_booking.total_price}"
      end
      
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一个可用航班
      flight = @available_flights.first
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
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
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
    end
  end
end
