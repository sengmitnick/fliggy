# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例29: 预订明天深圳到杭州最贵的航班
# 
# 任务描述:
#   Agent 需要在系统中搜索明天深圳到杭州的航班，
#   找到价格最高的航班并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索深圳到杭州的航线
#   2. 需要选择"明天"日期
#   3. 需要对比价格，选择最贵的
#   ❌ 价格排序反向（最贵），用于测试排序理解
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（深圳→杭州） (20分)
#   - 出发日期正确（明天） (20分)
#   - 选择了最贵的航班 (40分)
#
module V001V050
  class V029BookMostExpensiveFlightShenzhenHangzhouValidator < BaseValidator
    self.validator_id = 'v029_book_most_expensive_flight_shenzhen_hangzhou_validator'
    self.task_id = 'a83f2e9b-740d-4542-87e8-8e5d44e5cf6d'
    self.title = '给张三订明天深圳到杭州最贵的航班'
    self.description = '搜索明天深圳到杭州的航班，找到价格最高的航班并完成预订'
    self.timeout_seconds = 240
  
    def prepare
      @origin = '深圳'
      @destination = '杭州'
      @target_date = Date.current + 1.day
    
      available_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      )
    
      @highest_price = available_flights.maximum(:price)
    
      {
        task: "请给张三预订一张明天从#{@origin}到#{@destination}价格最高的航班",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多个航班可选，请选择价格最高的航班",
        available_flights_count: available_flights.count,
        highest_price: @highest_price
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_bookings = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bookings).not_to be_empty, "未找到任何Booking记录"
        @booking = all_bookings.first
        # Replaced by expect(all_bookings).not_to be_empty above, "未找到任何订单记录"
      end
    
      return unless @booking
    
      add_assertion "出发城市正确", weight: 10 do
        expect(@booking.flight.departure_city).to eq(@origin)
      end
    
      add_assertion "目的城市正确", weight: 10 do
        expect(@booking.flight.destination_city).to eq(@destination)
      end
    
      add_assertion "出发日期正确", weight: 20 do
        expect(@booking.flight.flight_date).to eq(@target_date)
      end
    
      add_assertion "选择了最贵的航班", weight: 30 do
        all_flights = Flight.where(
          departure_city: @origin,
          destination_city: @destination,
          flight_date: @target_date,
          data_version: 0
        )
      
        highest_price = all_flights.maximum(:price)
      
        expect(@booking.flight.price).to eq(highest_price),
          "未选择最贵航班。最高价: #{highest_price}元, 实际选择: #{@booking.flight.price}元"
      end
    
      # 断言5: 乘客信息正确（来自demo_user）
      add_assertion "乘客信息正确（张三 110101199001011234）", weight: 10 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq('110101199001011234'),
          "乘客身份证错误。期望: 110101199001011234（demo_user数据）, 实际: #{@booking.passenger_id_number}"
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
      ).order(price: :desc).first
    
      raise "No flights found for #{@origin} to #{@destination} on #{@target_date}" if target_flight.nil?
    
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
    
      { action: 'create_booking', flight_number: target_flight.flight_number, price: target_flight.price }
    end
    end
end
