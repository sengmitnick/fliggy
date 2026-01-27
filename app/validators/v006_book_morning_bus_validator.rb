# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 预订明天上午广州到深圳的大巴票
# 
# 任务描述:
#   Agent 需要在系统中搜索明天广州到深圳的大巴票，
#   找到上午（12点前）出发的班次并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（广州→深圳） (20分)
#   - 出发日期正确（明天） (20分)
#   - 时间段正确（上午） (40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_morning_bus_gz_to_sz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V006BookMorningBusValidator < BaseValidator
  self.validator_id = 'v006_book_morning_bus_validator'
  self.title = '预订明天上午广州到深圳的大巴票'
  self.description = '搜索明天广州到深圳的大巴票，找到上午（12点前）出发的班次并预订'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @origin = '广州'
    @destination = '深圳'
    @target_date = Date.current + 1.day  # 明天
    @morning_cutoff = '12:00'
    
    # 查找符合条件的班次（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    morning_buses = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    ).where('departure_time < ?', @morning_cutoff)
    
    @morning_count = morning_buses.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一张明天上午从#{@origin}到#{@destination}的大巴票",
      origin: @origin,
      destination: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      time_requirement: "上午（12:00之前出发）",
      hint: "系统中有多个班次可选，请选择上午出发的",
      morning_buses_count: @morning_count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @order = BusTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何大巴票订单记录"
    end
    
    return unless @order # 如果没有订单，后续断言无法继续
    
    # 断言2: 路线正确
    add_assertion "出发城市正确（广州）", weight: 10 do
      expect(@order.bus_ticket.origin).to eq(@origin)
    end
    
    add_assertion "目的城市正确（深圳）", weight: 10 do
      expect(@order.bus_ticket.destination).to eq(@destination)
    end
    
    # 断言3: 出发日期正确
    add_assertion "出发日期正确（明天）", weight: 20 do
      expect(@order.bus_ticket.departure_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{@order.bus_ticket.departure_date}"
    end
    
    # 断言4: 时间段正确（上午）（核心评分项）
    add_assertion "出发时间在上午（12:00之前）", weight: 40 do
      departure_time = @order.bus_ticket.departure_time
      
      expect(departure_time).to be < @morning_cutoff,
        "出发时间不在上午。要求: 12:00之前, 实际: #{departure_time}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      origin: @origin,
      destination: @destination,
      target_date: @target_date.to_s,
      morning_cutoff: @morning_cutoff,
      morning_count: @morning_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @morning_cutoff = data['morning_cutoff']
    @morning_count = data['morning_count']
  end
  
  # 模拟 AI Agent 操作：预订明天上午广州到深圳的大巴票
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的班次（上午）
    morning_buses = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    ).where('departure_time < ?', @morning_cutoff)
    
    # 随机选择一个
    target_bus = morning_buses.sample
    
    # 3. 创建订单（固定参数）
    order = BusTicketOrder.create!(
      bus_ticket_id: target_bus.id,
      user_id: user.id,
      passenger_count: 1,
      total_price: target_bus.price,
      status: 'pending'
    )
    
    # 创建乘客信息
    order.passengers.create!(
      passenger_name: '张三',
      passenger_id_number: '110101199001011234'
    )
    
    # 返回操作信息
    {
      action: 'create_bus_ticket_order',
      order_id: order.id,
      departure_time: target_bus.departure_time,
      arrival_time: target_bus.arrival_time,
      price: target_bus.price,
      user_email: user.email
    }
  end
end
