# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例27: 给张三预订明天上海到深圳任意航班
# 
# 任务描述:
#   Agent 需要在系统中搜索明天上海到深圳的航班，
#   选择任意一个航班并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索上海到深圳的航线
#   2. 需要选择"明天"日期
#   ❌ 无价格时间要求，任意航班即可
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 出发城市正确（上海） (20分)
#   - 目的城市正确（深圳） (20分)
#   - 出发日期正确（明天） (25分)
#   - 乘客信息正确（张三 110101199001011234） (10分)
#
module V001V050
  class V027BookAnyFlightShanghaiShenzhenValidator < BaseValidator
    self.validator_id = 'v027_book_any_flight_shanghai_shenzhen_validator'
    self.task_id = '4e165a52-184e-42c9-b89c-ef507e259ccb'
    self.title = '给张三预订明天上海到深圳任意航班'
    self.description = '预订明天上海到深圳任意航班'
    self.timeout_seconds = 240
  
    def prepare
      @origin = '上海'
      @destination = '深圳'
      @target_date = Date.current + 1.day
    
      available_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      )
    
      {
        task: "请给张三预订一张明天从#{@origin}到#{@destination}的任意航班",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个航班可选，选择任意一个即可",
        available_flights_count: available_flights.count
      }
    end
  
    def verify
      # 断言1: 订单已创建 (25分)
      add_assertion "订单已创建", weight: 25 do
        all_bookings = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bookings).not_to be_empty, "未找到任何Booking记录"
        @booking = all_bookings.first
      end
    
      return unless @booking
    
      # 断言2: 出发城市正确（上海） (20分)
      add_assertion "出发城市正确（上海）", weight: 20 do
        expect(@booking.flight.departure_city).to eq(@origin),
          "出发城市错误。期望: #{@origin}, 实际: #{@booking.flight.departure_city}"
      end
    
      # 断言3: 目的城市正确（深圳） (20分)
      add_assertion "目的城市正确（深圳）", weight: 20 do
        expect(@booking.flight.destination_city).to eq(@destination),
          "目的城市错误。期望: #{@destination}, 实际: #{@booking.flight.destination_city}"
      end
    
      # 断言4: 出发日期正确（明天） (25分)
      add_assertion "出发日期正确（明天）", weight: 25 do
        expect(@booking.flight.flight_date).to eq(@target_date),
          "出发日期不正确。预期: #{@target_date}, 实际: #{@booking.flight.flight_date}"
      end
    
      # 断言5: 乘客信息正确（张三 110101199001011234） (10分)
      add_assertion "乘客信息正确（张三 110101199001011234）", weight: 10 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq('110101199001011234'),
          "乘客身份证错误。期望: 110101199001011234, 实际: #{@booking.passenger_id_number}"
      end
    end
  
    private
  
    def execution_state_data
      { origin: @origin, destination: @destination, target_date: @target_date.to_s }
    end
  
    def restore_from_state(data)
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      target_flight = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      ).sample
    
      Booking.create!(
        flight_id: target_flight.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: target_flight.price,
        status: 'pending',
        accept_terms: true
      )
    
      { action: 'create_booking', flight_number: target_flight.flight_number }
    end
    end
end