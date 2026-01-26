# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例27: 预订明天上海到深圳任意航班
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
#   - 订单已创建 (30分)
#   - 出发城市正确（上海） (20分)
#   - 目的城市正确（深圳） (20分)
#   - 出发日期正确（明天） (30分)
#
class V027BookAnyFlightShanghaiShenzhenValidator < BaseValidator
  self.validator_id = 'v027_book_any_flight_shanghai_shenzhen_validator'
  self.title = '预订明天上海到深圳任意航班'
  self.description = '搜索明天上海到深圳的航班，选择任意一个航班并完成预订'
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
      task: "请预订一张明天从#{@origin}到#{@destination}的任意航班",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个航班可选，选择任意一个即可",
      available_flights_count: available_flights.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 30 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何订单记录"
    end
    
    return unless @booking
    
    add_assertion "出发城市正确（上海）", weight: 20 do
      expect(@booking.flight.departure_city).to eq(@origin),
        "出发城市错误。期望: #{@origin}, 实际: #{@booking.flight.departure_city}"
    end
    
    add_assertion "目的城市正确（深圳）", weight: 20 do
      expect(@booking.flight.destination_city).to eq(@destination),
        "目的城市错误。期望: #{@destination}, 实际: #{@booking.flight.destination_city}"
    end
    
    add_assertion "出发日期正确（明天）", weight: 30 do
      expect(@booking.flight.flight_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{@booking.flight.flight_date}"
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
