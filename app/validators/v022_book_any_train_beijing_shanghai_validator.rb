# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例22: 预订明天北京到上海任意高铁
# 
# 任务描述:
#   Agent 需要在系统中搜索明天北京到上海的高铁，
#   选择任意一班车次并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索北京到上海的路线
#   2. 需要选择"明天"日期（理解相对日期）
#   ❌ 无时间要求，无座位要求，任意车次即可
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 出发城市正确（北京） (20分)
#   - 到达城市正确（上海） (20分)
#   - 出发日期正确（明天） (30分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v022_book_any_train_beijing_shanghai_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V022BookAnyTrainBeijingShanghaiValidator < BaseValidator
  self.validator_id = 'v022_book_any_train_beijing_shanghai_validator'
  self.title = '预订明天北京到上海任意高铁'
  self.description = '搜索明天北京到上海的高铁，选择任意一班车次并完成预订'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @origin = '北京'
    @destination = '上海'
    @target_date = Date.current + 1.day  # 明天
    
    # 查找可用车次
    available_trains = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day)
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一张明天从#{@origin}到#{@destination}的任意高铁票",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个车次可选，选择任意一班即可",
      available_trains_count: available_trains.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 30 do
      @booking = TrainBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何火车票订单记录"
    end
    
    return unless @booking
    
    # 断言2: 出发城市正确
    add_assertion "出发城市正确（北京）", weight: 20 do
      expect(@booking.train.departure_city).to eq(@origin),
        "出发城市错误。期望: #{@origin}, 实际: #{@booking.train.departure_city}"
    end
    
    # 断言3: 到达城市正确
    add_assertion "到达城市正确（上海）", weight: 20 do
      expect(@booking.train.arrival_city).to eq(@destination),
        "到达城市错误。期望: #{@destination}, 实际: #{@booking.train.arrival_city}"
    end
    
    # 断言4: 出发日期正确
    add_assertion "出发日期正确（明天）", weight: 30 do
      booking_date = @booking.train.departure_time.in_time_zone.to_date
      expect(booking_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{booking_date}"
    end
  end
  
  private
  
  def execution_state_data
    {
      origin: @origin,
      destination: @destination,
      target_date: @target_date.to_s
    }
  end
  
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    # 随机选择一个车次
    target_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where(departure_time: @target_date.beginning_of_day..@target_date.end_of_day).sample
    
    seat = target_train.train_seats.find_by(seat_type: 'second_class')
    
    booking = TrainBooking.create!(
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
    
    {
      action: 'create_train_booking',
      booking_id: booking.id,
      train_number: target_train.train_number,
      user_email: user.email
    }
  end
end
