# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例11: 预订后天东京到京都的新干线列车票
# 
# 任务描述:
#   Agent 需要在系统中搜索后天东京到京都的新干线车票，
#   选择上午时段（12:00之前）的班次并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 地区正确（日本） (10分)
#   - 路线正确（东京→京都） (20分)
#   - 出发日期正确（后天） (20分)
#   - 时间段正确（上午） (30分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_japan_train_morning/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V007BookJapanTrainMorningValidator < BaseValidator
  self.validator_id = 'v007_book_japan_train_morning_validator'
  self.title = '预订后天东京到京都的上午新干线车票'
  self.description = '搜索后天东京到京都的新干线车票，选择上午（12:00之前）的班次并预订'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载
    @region = 'japan'
    @origin = '东京站'
    @destination = '京都站'
    @target_date = Date.current + 2.days  # 后天
    @morning_cutoff = '12:00'
    
    # 查找符合条件的班次（注意：查询基线数据 data_version=0）
    morning_trains = AbroadTicket.where(
      region: @region,
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      ticket_type: 'train',
      data_version: 0
    ).where('time_slot_start < ?', @morning_cutoff)
    
    @morning_count = morning_trains.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一张后天上午从#{@origin}到#{@destination}的新干线车票",
      region: @region,
      origin: @origin,
      destination: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      time_requirement: "上午（12:00之前出发）",
      hint: "系统中有多个班次可选，请选择上午出发的",
      morning_trains_count: @morning_count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @order = AbroadTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何境外票务订单记录"
    end
    
    return unless @order # 如果没有订单，后续断言无法继续
    
    # 断言2: 地区正确
    add_assertion "地区正确（日本）", weight: 10 do
      expect(@order.abroad_ticket.region).to eq(@region)
    end
    
    # 断言3: 路线正确
    add_assertion "出发地正确（东京站）", weight: 10 do
      expect(@order.abroad_ticket.origin).to eq(@origin)
    end
    
    add_assertion "目的地正确（京都站）", weight: 10 do
      expect(@order.abroad_ticket.destination).to eq(@destination)
    end
    
    # 断言4: 出发日期正确
    add_assertion "出发日期正确（后天）", weight: 20 do
      expect(@order.abroad_ticket.departure_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{@order.abroad_ticket.departure_date}"
    end
    
    # 断言5: 时间段正确（上午）（核心评分项）
    add_assertion "出发时间在上午（12:00之前）", weight: 30 do
      start_time = @order.abroad_ticket.time_slot_start
      
      expect(start_time).to be < @morning_cutoff,
        "出发时间不在上午。要求: 12:00之前, 实际: #{start_time}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      region: @region,
      origin: @origin,
      destination: @destination,
      target_date: @target_date.to_s,
      morning_cutoff: @morning_cutoff,
      morning_count: @morning_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @morning_cutoff = data['morning_cutoff']
    @morning_count = data['morning_count']
  end
  
  # 模拟 AI Agent 操作：预订后天上午东京到京都的新干线车票
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的班次（上午）
    morning_trains = AbroadTicket.where(
      region: @region,
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      ticket_type: 'train',
      data_version: 0
    ).where('time_slot_start < ?', @morning_cutoff)
    
    # 随机选择一个
    target_train = morning_trains.sample
    
    # 3. 创建订单（固定参数）
    order = AbroadTicketOrder.create!(
      abroad_ticket_id: target_train.id,
      user_id: user.id,
      passenger_name: '张三',
      contact_phone: '13800138000',
      contact_email: 'demo@travel01.com',
      passenger_type: 'adult',
      seat_category: 'standard',
      total_price: target_train.price,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_abroad_ticket_order',
      order_id: order.id,
      departure_date: target_train.departure_date.to_s,
      time_slot: "#{target_train.time_slot_start} - #{target_train.time_slot_end}",
      price: target_train.price,
      user_email: user.email
    }
  end
end
