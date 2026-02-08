# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例43: 预订后天上海到杭州下午汽车票（12:00后）
# 
# 任务描述:
#   Agent 需要在系统中搜索上海到杭州的汽车票，
#   找到发车时间在下午（12:00后）的班次并成功创建后天的订单
# 
# 复杂度分析:
#   1. 需要搜索上海到杭州的汽车票
#   2. 需要选择"后天"发车日期
#   3. 需要筛选发车时间≥12:00的班次
#   ❌ 时间段筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 出发地正确（上海） (15分)
#   - 目的地正确（杭州） (15分)
#   - 发车日期正确（后天） (10分)
#   - 发车时间在下午（≥12:00） (30分)
#   - 乘车人数正确（1人） (10分)
#
module V001V050
  class V043BookBusShanghaiHangzhouValidator < BaseValidator
    self.validator_id = 'v043_book_bus_shanghai_hangzhou_validator'
    self.task_id = '2a23e38d-47cb-47ea-bf9a-0d132a606f5f'
    self.title = '预订后天上海到杭州下午汽车票（12:00后，1人）'
    self.description = '搜索上海到杭州的汽车票，找到发车时间在12:00后的班次'
    self.timeout_seconds = 240
  
    def prepare
      @origin = '上海'
      @destination = '杭州'
      @target_date = Date.current + 2.days
      @afternoon_cutoff = '12:00'
    
      afternoon_buses = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('departure_time >= ?', @afternoon_cutoff)
    
      {
        task: "请预订后天从#{@origin}到#{@destination}的下午汽车票（发车时间≥12:00）",
        origin: @origin,
        destination: @destination,
        date: @target_date.to_s,
        date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        time_requirement: "下午（12:00之后出发）",
        hint: "系统中有多个下午班次，选择发车时间≥12:00的即可",
        afternoon_buses_count: afternoon_buses.count
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
    
      add_assertion "发车日期正确（后天）", weight: 10 do
        expect(@order.bus_ticket.departure_date).to eq(@target_date),
          "发车日期不正确。期望: #{@target_date}（后天）, 实际: #{@order.bus_ticket.departure_date}"
      end
    
      add_assertion "发车时间在下午（≥12:00）", weight: 30 do
        departure_time = @order.bus_ticket.departure_time
      
        expect(departure_time >= @afternoon_cutoff).to be_truthy,
          "发车时间不符合要求。要求: ≥12:00, 实际: #{departure_time}"
      end
    
      add_assertion "乘车人数正确（1人）", weight: 10 do
        expect(@order.passenger_count).to eq(1),
          "乘车人数不正确。期望: 1人, 实际: #{@order.passenger_count}人"
      end
    end
  
    private
  
    def execution_state_data
      { origin: @origin, destination: @destination, target_date: @target_date.to_s, afternoon_cutoff: @afternoon_cutoff }
    end
  
    def restore_from_state(data)
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
      @afternoon_cutoff = data['afternoon_cutoff']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_ticket = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('departure_time >= ?', @afternoon_cutoff).sample
    
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
end
