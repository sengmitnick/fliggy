# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例45: 预订大后天深圳到广州最便宜汽车票（预算≤50元）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳到广州的汽车票，
#   找到价格≤50元的班次中最便宜的并成功创建大后天的订单
# 
# 复杂度分析:
#   1. 需要搜索深圳到广州的汽车票
#   2. 需要选择"大后天"发车日期
#   3. 需要筛选价格≤50元的班次
#   4. 需要在符合预算的班次中选择最便宜的
#   ❌ 价格优先，简化版性价比
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 出发地正确（深圳） (15分)
#   - 目的地正确（广州） (15分)
#   - 发车日期正确（大后天） (10分)
#   - 价格符合预算（≤50元） (30分)
#   - 乘车人数正确（1人） (10分)
#
module V001V050
  class V045BookBusShenzhenGuangzhouValidator < BaseValidator
    self.validator_id = 'v045_book_bus_shenzhen_guangzhou_validator'
    self.task_id = '7de96a19-469c-4768-8dec-ed836ac17124'
    self.title = '预订3天后深圳到广州最便宜汽车票（预算≤50元，1人）'
    self.description = '搜索深圳到广州的汽车票，找到价格≤50元的班次'
    self.timeout_seconds = 240
  
    def prepare
      @origin = '深圳'
      @destination = '广州'
      @target_date = Date.current + 3.days
      @budget = 50
    
      eligible_tickets = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('price <= ?', @budget)
    
      @lowest_price = eligible_tickets.minimum(:price)
    
      {
        task: "请预订大后天从#{@origin}到#{@destination}的最便宜汽车票（预算≤#{@budget}元）",
        origin: @origin,
        destination: @destination,
        date: @target_date.to_s,
        date_description: "大后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        budget: @budget,
        hint: "系统中有多个符合预算的班次，请选择价格最低的",
        eligible_tickets_count: eligible_tickets.count,
        lowest_price: @lowest_price
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_bus_ticket_orders = BusTicketOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bus_ticket_orders).not_to be_empty, "未找到任何BusTicketOrder记录"
        @order = all_bus_ticket_orders.first
        # Replaced by expect(all_bus_ticket_orders).not_to be_empty above, "未找到任何汽车票订单记录"
      end
    
      return unless @order
    
      add_assertion "出发地正确（#{@origin}）", weight: 15 do
        expect(@order.bus_ticket.origin).to eq(@origin),
          "出发地错误。期望: #{@origin}, 实际: #{@order.bus_ticket.origin}"
      end
    
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@order.bus_ticket.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@order.bus_ticket.destination}"
      end
    
      add_assertion "发车日期正确（大后天）", weight: 10 do
        expect(@order.bus_ticket.departure_date).to eq(@target_date),
          "发车日期不正确。期望: #{@target_date}（大后天）, 实际: #{@order.bus_ticket.departure_date}"
      end
    
      add_assertion "价格符合预算（≤#{@budget}元）", weight: 30 do
        price = @order.bus_ticket.price
      
        expect(price <= @budget).to be_truthy,
          "价格超出预算。预算: ≤#{@budget}元, 实际: #{price}元"
      end
    
      add_assertion "乘车人数正确（1人）", weight: 10 do
        expect(@order.passenger_count).to eq(1),
          "乘车人数不正确。期望: 1人, 实际: #{@order.passenger_count}人"
      end
    end
  
    private
  
    def execution_state_data
      { origin: @origin, destination: @destination, target_date: @target_date.to_s, budget: @budget }
    end
  
    def restore_from_state(data)
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
      @budget = data['budget']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_ticket = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('price <= ?', @budget)
       .order(:price)
       .first
    
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
    
      { action: 'create_bus_order', departure_time: target_ticket.departure_time, price: target_ticket.price }
    end
    end
end
