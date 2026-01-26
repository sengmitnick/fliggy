# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例24: 预订明天杭州到北京最晚的高铁
# 
# 任务描述:
#   Agent 需要在系统中搜索明天杭州到北京的所有高铁，
#   找到发车时间最晚的车次并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索杭州到北京的路线
#   2. 需要选择"明天"日期
#   3. 需要对比发车时间，选择最晚的
#   ❌ 时间排序反向（最晚而非最早），降低复杂度
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（杭州→北京） (20分)
#   - 出发日期正确（明天） (20分)
#   - 选择了最晚的车次 (40分)
#
class V024BookLatestTrainHangzhouBeijingValidator < BaseValidator
  self.validator_id = 'v024_book_latest_train_hangzhou_beijing_validator'
  self.title = '预订明天杭州到北京最晚的高铁'
  self.description = '在明天的车次中找到发车时间最晚的高铁并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '杭州'
    @destination = '北京'
    @target_date = Date.current + 1.day
    
    latest_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
     .order(departure_time: :desc)
     .first
    
    @latest_departure_time = latest_train&.departure_time
    
    {
      task: "请预订一张明天从#{@origin}到#{@destination}最晚的高铁票",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个车次可选，请选择发车时间最晚的",
      latest_time: @latest_departure_time&.strftime('%H:%M')
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = TrainBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何火车票订单记录"
    end
    
    return unless @booking
    
    add_assertion "出发城市正确", weight: 10 do
      expect(@booking.train.departure_city).to eq(@origin)
    end
    
    add_assertion "到达城市正确", weight: 10 do
      expect(@booking.train.arrival_city).to eq(@destination)
    end
    
    add_assertion "出发日期正确", weight: 20 do
      booking_date = @booking.train.departure_time.in_time_zone.to_date
      expect(booking_date).to eq(@target_date)
    end
    
    add_assertion "选择了最晚的车次", weight: 40 do
      all_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination
      ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
      
      latest_time = all_trains.maximum(:departure_time)
      
      expect(@booking.train.departure_time).to eq(latest_time),
        "未选择最晚车次。最晚发车: #{latest_time.strftime('%H:%M')}, 实际选择: #{@booking.train.departure_time.strftime('%H:%M')}"
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
    
    target_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
     .order(departure_time: :desc)
     .first
    
    seat = target_train.train_seats.find_by(seat_type: 'second_class')
    
    TrainBooking.create!(
      train_id: target_train.id,
      user_id: user.id,
      passenger_name: passenger.name,
      passenger_id_number: passenger.id_number,
      contact_phone: passenger.phone,
      seat_type: 'second_class',
      accept_terms: true,
      total_price: seat.price,
      status: 'pending'
    )
    
    { action: 'create_train_booking', train_number: target_train.train_number }
  end
end
