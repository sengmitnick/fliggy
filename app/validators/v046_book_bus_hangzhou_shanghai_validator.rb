# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例46: 预订后天杭州到上海晚上汽车票（18:00后）
# 
# 任务描述:
#   Agent 需要在系统中搜索杭州到上海的汽车票，
#   找到发车时间在晚上（18:00后）的班次并成功创建后天的订单
# 
# 复杂度分析:
#   1. 需要搜索杭州到上海的汽车票
#   2. 需要选择"后天"发车日期
#   3. 需要筛选发车时间≥18:00的班次
#   ❌ 时间段筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 出发地正确（杭州） (20分)
#   - 目的地正确（上海） (20分)
#   - 发车时间在晚上（≥18:00） (35分)
#
class V046BookBusHangzhouShanghaiValidator < BaseValidator
  self.validator_id = 'v046_book_bus_hangzhou_shanghai_validator'
  self.title = '预订后天杭州到上海晚上汽车票（18:00后）'
  self.description = '搜索杭州到上海的汽车票，找到发车时间在18:00后的班次'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '杭州'
    @destination = '上海'
    @target_date = Date.current + 2.days
    @evening_cutoff = '18:00'
    
    evening_buses = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    ).where('departure_time >= ?', @evening_cutoff)
    
    {
      task: "请预订后天从#{@origin}到#{@destination}的晚上汽车票（发车时间≥18:00）",
      origin: @origin,
      destination: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      time_requirement: "晚上（18:00之后出发）",
      hint: "系统中有多个晚上班次，选择发车时间≥18:00的即可",
      evening_buses_count: evening_buses.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 25 do
      @order = BusTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何汽车票订单记录"
    end
    
    return unless @order
    
    add_assertion "出发地正确（#{@origin}）", weight: 20 do
      expect(@order.bus_ticket.origin).to eq(@origin)
    end
    
    add_assertion "目的地正确（#{@destination}）", weight: 20 do
      expect(@order.bus_ticket.destination).to eq(@destination)
    end
    
    add_assertion "发车时间在晚上（≥18:00）", weight: 35 do
      departure_time = @order.bus_ticket.departure_time
      
      expect(departure_time >= @evening_cutoff).to be_truthy,
        "发车时间不符合要求。要求: ≥18:00, 实际: #{departure_time}"
    end
  end
  
  private
  
  def execution_state_data
    { origin: @origin, destination: @destination, target_date: @target_date.to_s, evening_cutoff: @evening_cutoff }
  end
  
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @evening_cutoff = data['evening_cutoff']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_ticket = BusTicket.where(
      origin: @origin,
      destination: @destination,
      departure_date: @target_date,
      data_version: 0
    ).where('departure_time >= ?', @evening_cutoff).sample
    
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
