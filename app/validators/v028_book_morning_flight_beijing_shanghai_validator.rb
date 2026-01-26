# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例28: 预订后天北京到上海早班航班（12点前起飞）
# 
# 任务描述:
#   Agent 需要在系统中搜索后天北京到上海的航班，
#   找到12点前起飞的早班航班并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索北京到上海的航线
#   2. 需要选择"后天"日期
#   3. 需要筛选起飞时间<12:00的航班
#   ❌ 时段筛选，无价格要求
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（北京→上海） (20分)
#   - 出发日期正确（后天） (20分)
#   - 起飞时间正确（12点前） (40分)
#
class V028BookMorningFlightBeijingShanghaiValidator < BaseValidator
  self.validator_id = 'v028_book_morning_flight_beijing_shanghai_validator'
  self.title = '预订后天北京到上海早班航班（12点前起飞）'
  self.description = '搜索后天北京到上海的航班，找到12点前起飞的早班航班并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '北京'
    @destination = '上海'
    @target_date = Date.current + 2.days
    @morning_cutoff = '12:00'
    
    morning_flights = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      data_version: 0
    ).where("EXTRACT(HOUR FROM departure_time) < 12")
    
    {
      task: "请预订一张后天从#{@origin}到#{@destination}的早班航班（12点前起飞）",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      time_requirement: "12:00之前起飞",
      hint: "系统中有多个航班可选，请选择12点前起飞的早班航班",
      morning_flights_count: morning_flights.count
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
    
    add_assertion "起飞时间在12点前", weight: 40 do
      departure_time = @booking.flight.departure_time
      departure_hour = departure_time.is_a?(Time) ? departure_time.hour : Time.parse(departure_time).hour
      expect(departure_hour < 12).to be_truthy,
        "起飞时间不在早班时段。要求: 12:00之前, 实际: #{departure_time}"
    end
  end
  
  private
  
  def execution_state_data
    { origin: @origin, destination: @destination, target_date: @target_date.to_s, morning_cutoff: @morning_cutoff }
  end
  
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @morning_cutoff = data['morning_cutoff']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    target_flight = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      data_version: 0
    ).where("EXTRACT(HOUR FROM departure_time) < 12").sample
    
    raise "No morning flights found for #{@origin} to #{@destination} on #{@target_date}" if target_flight.nil?
    
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
