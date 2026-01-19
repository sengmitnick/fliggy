# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例10: 搜索后天杭州到苏州行程时间最短的班次
# 
# 任务描述:
#   Agent 需要搜索后天杭州到苏州的所有大巴班次，
#   找出行程时间最短的班次并创建订单
# 
# 评分标准:
#   - 搜索到了所有可用班次 (20分)
#   - 正确识别最短行程时间 (30分)
#   - 成功创建订单 (20分)
#   - 订单信息准确 (30分)
# 
# 难点:
#   - 需要计算行程时间（到达时间 - 出发时间）
#   - 需要对比多个班次找出最短的
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_fastest_bus_hz_to_sz/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchFastestBusValidator < BaseValidator
  self.validator_id = 'search_fastest_bus_hz_to_sz'
  self.title = '搜索后天杭州到苏州行程时间最短的班次'
  self.description = '搜索后天杭州到苏州的所有班次，找出行程时间最短的并预订'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    @origin = '杭州'
    @destination = '苏州'
    @target_date = Date.current + 2.days  # 后天
    
    # 查找所有班次（注意：查询基线数据）
    buses = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    )
    
    # 计算每个班次的行程时间
    @bus_durations = buses.map do |bus|
      duration = bus.duration_minutes
      {
        id: bus.id,
        departure_time: bus.departure_time,
        arrival_time: bus.arrival_time,
        duration_minutes: duration
      }
    end.compact.select { |b| b[:duration_minutes] > 0 }
    
    # 找出最短时间
    @fastest_bus = @bus_durations.min_by { |b| b[:duration_minutes] }
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索后天从#{@origin}到#{@destination}的所有大巴班次，找出行程时间最短的并预订",
      origin: @origin,
      destination: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "需要对比各班次的行程时间（到达时间 - 出发时间）",
      total_buses: buses.count,
      fastest_duration_minutes: @fastest_bus[:duration_minutes]
    }
  end
  
  # 验证阶段：检查是否找到并预订了最短行程的班次
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @order = BusTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何大巴票订单记录"
    end
    
    return unless @order
    
    # 断言2: 路线正确
    add_assertion "路线正确（杭州→苏州）", weight: 10 do
      expect(@order.bus_ticket.origin).to eq(@origin)
      expect(@order.bus_ticket.destination).to eq(@destination)
    end
    
    # 断言3: 日期正确
    add_assertion "出发日期正确", weight: 10 do
      expect(@order.bus_ticket.departure_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{@order.bus_ticket.departure_date}"
    end
    
    # 断言4: 正确识别最短行程时间（核心评分）
    add_assertion "选择了行程时间最短的班次", weight: 30 do
      # 重新计算所有班次的行程时间
      all_buses = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      )
      
      # 找出最短时间
      shortest_duration = all_buses.map(&:duration_minutes).compact.min
      
      # 实际预订的班次时间
      booked_duration = @order.bus_ticket.duration_minutes
      
      expect(booked_duration).to eq(shortest_duration),
        "未选择行程时间最短的班次。最短: #{shortest_duration}分钟, 实际选择: #{booked_duration}分钟"
    end
    
    # 断言5: 订单信息准确
    add_assertion "订单金额准确", weight: 30 do
      expected_price = @order.bus_ticket.price
      
      expect(@order.total_price).to be_within(1).of(expected_price),
        "订单金额不正确。预期: ¥#{expected_price}, 实际: ¥#{@order.total_price}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      origin: @origin,
      destination: @destination,
      target_date: @target_date.to_s,
      bus_durations: @bus_durations,
      fastest_bus: @fastest_bus
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @bus_durations = data['bus_durations']
    @fastest_bus = data['fastest_bus']
  end
  
  # 模拟 AI Agent 操作：搜索杭州到苏州最短行程班次并预订
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找所有班次
    all_buses = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    )
    
    # 3. 找出行程时间最短的
    target_bus = all_buses.min_by { |bus| bus.duration_minutes || Float::INFINITY }
    
    # 4. 创建订单（固定参数）
    order = BusTicketOrder.create!(
      bus_ticket_id: target_bus.id,
      user_id: user.id,
      passenger_name: '张三',
      passenger_id_number: '110101199001011234',
      contact_phone: '13800138000',
      total_price: target_bus.price,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_bus_ticket_order',
      order_id: order.id,
      departure_time: target_bus.departure_time,
      arrival_time: target_bus.arrival_time,
      duration_minutes: target_bus.duration_minutes,
      price: target_bus.price,
      user_email: user.email
    }
  end
end
