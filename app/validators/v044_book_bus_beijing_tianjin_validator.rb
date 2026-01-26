# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例44: 预订明天北京到天津最早汽车票
# 
# 任务描述:
#   Agent 需要在系统中搜索北京到天津的汽车票，
#   找到发车时间最早的班次并成功创建明天的订单
# 
# 复杂度分析:
#   1. 需要搜索北京到天津的汽车票
#   2. 需要选择"明天"发车日期
#   3. 需要找到发车时间最早的班次
#   ❌ 时间优先，无价格限制
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 出发地正确（北京） (25分)
#   - 目的地正确（天津） (25分)
#   - 发车日期正确（明天） (20分)
#
class V044BookBusBeijingTianjinValidator < BaseValidator
  self.validator_id = 'v044_book_bus_beijing_tianjin_validator'
  self.title = '预订明天北京到天津最早汽车票'
  self.description = '搜索北京到天津的汽车票，找到发车时间最早的班次'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '北京'
    @destination = '天津'
    @target_date = Date.current + 1.day
    
    available_tickets = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    )
    
    @earliest_time = available_tickets.minimum(:departure_time)
    
    {
      task: "请预订明天从#{@origin}到#{@destination}的最早汽车票",
      origin: @origin,
      destination: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个班次，请选择发车时间最早的",
      available_tickets_count: available_tickets.count,
      earliest_time: @earliest_time
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 30 do
      @order = BusTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何汽车票订单记录"
    end
    
    return unless @order
    
    add_assertion "出发地正确（#{@origin}）", weight: 25 do
      expect(@order.bus_ticket.origin).to eq(@origin)
    end
    
    add_assertion "目的地正确（#{@destination}）", weight: 25 do
      expect(@order.bus_ticket.destination).to eq(@destination)
    end
    
    add_assertion "发车日期正确（明天）", weight: 20 do
      expect(@order.bus_ticket.departure_date).to eq(@target_date)
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
    
    target_ticket = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    ).order(:departure_time).first
    
    order = BusTicketOrder.create!(
      bus_ticket_id: target_ticket.id,
      user_id: user.id,
      passenger_count: 1,
      total_price: target_ticket.price,
      status: 'pending'
    )
    
    order.passengers.create!(
      passenger_name: '张三',
      passenger_id_number: '110101199001011234'
    )
    
    { action: 'create_bus_order', departure_time: target_ticket.departure_time }
  end
end
