# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例25: 预订后天深圳到广州最快的高铁
# 
# 任务描述:
#   Agent 需要在系统中搜索后天深圳到广州的所有高铁，
#   找到行程时间最短的车次并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索深圳到广州的路线
#   2. 需要选择"后天"日期
#   3. 需要按行程时长排序，选择最快的
#   ❌ 按duration字段排序即可，无需复杂计算
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（深圳→广州） (20分)
#   - 出发日期正确（后天） (20分)
#   - 选择了最快的车次 (40分)
#
class V025BookFastestTrainShenzhenGuangzhouValidator < BaseValidator
  self.validator_id = 'v025_book_fastest_train_shenzhen_guangzhou_validator'
  self.title = '预订后天深圳到广州最快的高铁'
  self.description = '在后天的车次中找到行程时间最短的高铁并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '深圳'
    @destination = '广州'
    @target_date = Date.current + 2.days
    
    fastest_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
     .order(:duration)
     .first
    
    @fastest_duration = fastest_train&.duration
    
    {
      task: "请预订一张后天从#{@origin}到#{@destination}行程时间最短的高铁票",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个车次可选，请选择行程时间最短的",
      fastest_duration: @fastest_duration
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
    
    add_assertion "选择了最快的车次", weight: 40 do
      all_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination
      ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
      
      fastest_duration = all_trains.minimum(:duration)
      
      expect(@booking.train.duration).to eq(fastest_duration),
        "未选择最快车次。最短行程: #{fastest_duration}分钟, 实际选择: #{@booking.train.duration}分钟"
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
     .order(:duration)
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
