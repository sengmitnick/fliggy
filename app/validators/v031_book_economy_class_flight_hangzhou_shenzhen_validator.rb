# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例31: 预订明天杭州到深圳经济舱航班
# 
# 任务描述:
#   Agent 需要在系统中搜索明天杭州到深圳的航班，
#   选择经济舱航班并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索杭州到深圳的航线
#   2. 需要选择"明天"日期
#   3. 需要筛选经济舱舱位
#   ❌ 舱位筛选，无价格时间要求
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（杭州→深圳） (30分)
#   - 出发日期正确（明天） (20分)
#   - 舱位正确（经济舱） (30分)
#
class V031BookEconomyClassFlightHangzhouShenzhenValidator < BaseValidator
  self.validator_id = 'v031_book_economy_class_flight_hangzhou_shenzhen_validator'
  self.task_id = '8a584a64-cfdb-471b-88f4-93b13e200d0b'
  self.title = '预订明天杭州到深圳经济舱航班'
  self.description = '搜索明天杭州到深圳的航班，选择经济舱航班并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '杭州'
    @destination = '深圳'
    @target_date = Date.current + 1.day
    @seat_class = 'economy'
    
    economy_flights = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      seat_class: @seat_class,
      data_version: 0
    )
    
    {
      task: "请预订一张明天从#{@origin}到#{@destination}的经济舱航班",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      cabin_requirement: "经济舱",
      hint: "系统中有多个航班可选，请选择经济舱",
      economy_flights_count: economy_flights.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何订单记录"
    end
    
    return unless @booking
    
    add_assertion "出发城市正确", weight: 15 do
      expect(@booking.flight.departure_city).to eq(@origin)
    end
    
    add_assertion "目的城市正确", weight: 15 do
      expect(@booking.flight.destination_city).to eq(@destination)
    end
    
    add_assertion "出发日期正确", weight: 20 do
      expect(@booking.flight.flight_date).to eq(@target_date)
    end
    
    add_assertion "舱位正确（经济舱）", weight: 30 do
      expect(@booking.flight.seat_class).to eq(@seat_class),
        "舱位错误。期望: 经济舱, 实际: #{@booking.flight.seat_class}"
    end
  end
  
  private
  
  def execution_state_data
    { origin: @origin, destination: @destination, target_date: @target_date.to_s, seat_class: @seat_class }
  end
  
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @seat_class = data['seat_class']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    target_flight = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      seat_class: @seat_class,
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