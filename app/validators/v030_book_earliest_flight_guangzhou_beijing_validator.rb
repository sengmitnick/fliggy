# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例30: 预订后天广州到北京最早起飞的航班
# 
# 任务描述:
#   Agent 需要在系统中搜索后天广州到北京的航班，
#   找到起飞时间最早的航班并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索广州到北京的航线
#   2. 需要选择"后天"日期
#   3. 需要按起飞时间排序，选择最早的
#   ❌ 时间排序，无价格要求
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（广州→北京） (20分)
#   - 出发日期正确（后天） (20分)
#   - 选择了最早起飞的航班 (40分)
#
class V030BookEarliestFlightGuangzhouBeijingValidator < BaseValidator
  self.validator_id = 'v030_book_earliest_flight_guangzhou_beijing_validator'
  self.task_id = '530b0d27-0eff-46b7-a7b1-d7226603ad4b'
  self.title = '预订后天广州到北京最早起飞的航班'
  self.description = '搜索后天广州到北京的航班，找到起飞时间最早的航班并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '广州'
    @destination = '北京'
    @target_date = Date.current + 2.days
    
    earliest_flight = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      data_version: 0
    ).order(:departure_time).first
    
    @earliest_time = earliest_flight&.departure_time
    
    {
      task: "请预订一张后天从#{@origin}到#{@destination}起飞时间最早的航班",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个航班可选，请选择起飞时间最早的",
      earliest_time: @earliest_time
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何订单记录"
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
    
    add_assertion "选择了最早起飞的航班", weight: 40 do
      all_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date
      )
      
      earliest_time = all_flights.minimum(:departure_time)
      
      expect(@booking.flight.departure_time).to eq(earliest_time),
        "未选择最早起飞航班。最早: #{earliest_time}, 实际选择: #{@booking.flight.departure_time}"
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
    ).order(:departure_time).first
    
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