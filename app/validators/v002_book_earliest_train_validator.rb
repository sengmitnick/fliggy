# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例3: 预订明天上海到杭州最早的高铁（二等座）
# 
# 任务描述:
#   Agent 需要在系统中搜索明天上海到杭州的所有高铁，
#   找到发车时间最早的车次并成功创建订单。
#   优先选择二等座（最常用的座位类型）。
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确 (20分)
#   - 出发日期正确 (20分)
#   - 选择了最早的车次 (30分)
#   - 选择了二等座 (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_earliest_train_sh_to_hz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V002BookEarliestTrainValidator < BaseValidator
  self.validator_id = 'v002_book_earliest_train_validator'
  self.title = '预订明天上海到杭州最早的高铁（二等座）'
  self.description = '在明天的车次中找到发车时间最早的高铁并完成预订，优先选择二等座'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @origin = '上海'
    @destination = '杭州'
    @target_date = Date.current + 1.day  # 明天
    
    # 查找最早的车次（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    earliest_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where("DATE(departure_time) = ?", @target_date)
     .order(:departure_time)
     .first
    
    @earliest_departure_time = earliest_train&.departure_time
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一张明天从#{@origin}到#{@destination}最早的高铁票（二等座）",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个车次可选，请选择发车时间最早的，并选择二等座",
      available_trains_count: Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time) = ?", @target_date).count,
      earliest_time: @earliest_departure_time&.strftime('%H:%M')
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @booking = TrainBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何火车票订单记录"
    end
    
    return unless @booking # 如果没有订单，后续断言无法继续
    
    # 断言2: 路线正确
    add_assertion "出发城市正确", weight: 10 do
      expect(@booking.train.departure_city).to eq(@origin)
    end
    
    add_assertion "到达城市正确", weight: 10 do
      expect(@booking.train.arrival_city).to eq(@destination)
    end
    
    # 断言3: 出发日期正确
    add_assertion "出发日期正确", weight: 20 do
      booking_date = @booking.train.departure_time.to_date
      expect(booking_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{booking_date}"
    end
    
    # 断言4: 选择了最早的车次（核心评分项）
    add_assertion "选择了最早的车次", weight: 30 do
      # 查找该路线当天的所有车次
      all_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination
      ).where("DATE(departure_time) = ?", @target_date)
      
      # 找出最早的发车时间
      earliest_time = all_trains.minimum(:departure_time)
      
      # 验证预订的车次是否为最早的
      expect(@booking.train.departure_time).to eq(earliest_time),
        "未选择最早车次。最早发车: #{earliest_time.strftime('%H:%M')} (#{all_trains.find_by(departure_time: earliest_time).train_number}), " \
        "实际选择: #{@booking.train.departure_time.strftime('%H:%M')} (#{@booking.train.train_number})"
    end
    
    # 断言5: 选择了二等座
    add_assertion "选择了二等座", weight: 10 do
      expect(@booking.seat_type).to eq('second_class'),
        "应选择二等座，实际选择: #{@booking.seat_type_label}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      target_date: @target_date.to_s,
      origin: @origin,
      destination: @destination,
      earliest_departure_time: @earliest_departure_time&.iso8601
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @target_date = Date.parse(data['target_date'])
    @origin = data['origin']
    @destination = data['destination']
    @earliest_departure_time = Time.zone.parse(data['earliest_departure_time']) if data['earliest_departure_time']
  end
  
  # 模拟 AI Agent 操作：预订上海到杭州最早的高铁
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找乘客（数据包中已创建）
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    # 3. 查找目标车次（最早的）
    target_train = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where("DATE(departure_time) = ?", @target_date)
     .order(:departure_time)
     .first
    
    # 4. 查找二等座座位
    seat = target_train.train_seats.find_by(seat_type: 'second_class')
    
    # 5. 创建订单（固定参数）
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
    
    # 返回操作信息
    {
      action: 'create_train_booking',
      booking_id: booking.id,
      train_number: target_train.train_number,
      departure_time: target_train.departure_time.strftime('%H:%M'),
      seat_price: seat.price,
      passenger_name: passenger.name,
      user_email: user.email
    }
  end
end
