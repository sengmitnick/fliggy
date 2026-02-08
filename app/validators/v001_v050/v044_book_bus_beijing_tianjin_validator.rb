# frozen_string_literal: true

require_relative '../base_validator'

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
#   - 订单已创建 (25分)
#   - 出发地正确（北京） (20分)
#   - 目的地正确（天津） (20分)
#   - 发车日期正确（明天） (20分)
#   - 乘车人数正确（1人） (10分)
#   - 乘客信息正确（来自demo_user） (5分)
#
module V001V050
  class V044BookBusBeijingTianjinValidator < BaseValidator
    self.validator_id = 'v044_book_bus_beijing_tianjin_validator'
    self.task_id = '68156569-46f4-4a08-99a1-e25e9c4d498f'
    self.title = '给张三预订明天北京到天津最早的汽车票'
    self.description = 'Agent 需要为张三预订明天从北京到天津的汽车票，找到发车时间最早的班次'
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
      add_assertion "订单已创建", weight: 25 do
        all_bus_ticket_orders = BusTicketOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bus_ticket_orders).not_to be_empty, "未找到任何BusTicketOrder记录"
        @order = all_bus_ticket_orders.first
        # Replaced by expect(all_bus_ticket_orders).not_to be_empty above, "未找到任何汽车票订单记录"
      end
    
      return unless @order
    
      add_assertion "出发地正确（#{@origin}）", weight: 20 do
        expect(@order.bus_ticket.origin).to eq(@origin),
          "出发地不正确。期望: #{@origin}, 实际: #{@order.bus_ticket.origin}"
      end
    
      add_assertion "目的地正确（#{@destination}）", weight: 20 do
        expect(@order.bus_ticket.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@order.bus_ticket.destination}"
      end
    
      add_assertion "发车日期正确（明天）", weight: 20 do
        expect(@order.bus_ticket.departure_date).to eq(@target_date),
          "发车日期不正确。期望: #{@target_date}（明天）, 实际: #{@order.bus_ticket.departure_date}"
      end
    
      add_assertion "乘车人数正确（1人）", weight: 10 do
        expect(@order.passenger_count).to eq(1),
          "乘车人数不正确。期望: 1人, 实际: #{@order.passenger_count}人"
      end
    
      add_assertion "乘客信息正确（张三 110101199001011234）", weight: 5 do
        passenger = @order.passengers.first
        expect(passenger&.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{passenger&.passenger_name}"
        expect(passenger&.passenger_id_number).to eq('110101199001011234'),
          "乘客身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{passenger&.passenger_id_number}"
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
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
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
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number
      )
    
      { action: 'create_bus_order', departure_time: target_ticket.departure_time }
    end
    end
end
