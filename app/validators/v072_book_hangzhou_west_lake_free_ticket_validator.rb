# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例72: 预订5天后上海迪士尼乐园儿童票
class V072BookHangzhouWestLakeFreeTicketValidator < BaseValidator
  self.validator_id = 'v072_book_hangzhou_west_lake_free_ticket_validator'
  self.title = '预订5天后上海迪士尼乐园儿童票（1张，最便宜）'
  self.description = '预订上海迪士尼乐园儿童票，选择最便宜供应商'
  self.timeout_seconds = 240
  
  def prepare
    @attraction_name = '上海迪士尼乐园'
    @ticket_type = 'child'
    @visit_date = Date.current + 5.days
    @quantity = 1
    
    @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
    raise "未找到景点: #{@attraction_name}" unless @attraction
    
    @child_tickets = Ticket.where(
      attraction_id: @attraction.id,
      ticket_type: @ticket_type,
      data_version: 0
    )
    
    cheapest_supplier = nil
    min_price = Float::INFINITY
    
    @child_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_price
          min_price = ts.current_price
          cheapest_supplier = ts
        end
      end
    end
    
    @best_ticket_supplier = cheapest_supplier
    @best_price = min_price
    
    days_until_visit = (@visit_date - Date.current).to_i
    date_desc = case days_until_visit
    when 0 then "今天"
    when 1 then "明天"
    when 2 then "后天"
    else "#{days_until_visit}天后"
    end
    
    {
      task: "请预订#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的儿童票，选择最便宜的供应商",
      attraction_name: @attraction_name,
      ticket_type: "儿童票",
      visit_date: @visit_date.to_s,
      date_description: "#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）",
      quantity: @quantity,
      hint: "系统中有多个供应商提供儿童票。请对比价格后选择最便宜的",
      available_tickets_count: @child_tickets.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 30 do
      @ticket_order = TicketOrder.order(created_at: :desc).first
      expect(@ticket_order).not_to be_nil, "未找到任何门票订单记录"
    end
    
    return unless @ticket_order
    
    add_assertion "景点正确（#{@attraction_name}）", weight: 20 do
      ticket = @ticket_order.ticket
      attraction = ticket.attraction
      
      expect(attraction.name).to eq(@attraction_name),
        "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
    end
    
    add_assertion "票种正确（儿童票）", weight: 30 do
      ticket = @ticket_order.ticket
      
      expect(ticket.ticket_type).to eq(@ticket_type),
        "票种错误。期望: 儿童票(child), 实际: #{ticket.ticket_type}"
    end
    
    add_assertion "游玩日期正确（5天后，#{@visit_date}）", weight: 10 do
      expect(@ticket_order.visit_date).to eq(@visit_date),
        "游玩日期错误。期望: #{@visit_date}（5天后）, 实际: #{@ticket_order.visit_date}"
    end
    
    add_assertion "选择了最便宜的供应商", weight: 10 do
      all_prices = []
      @child_tickets.each do |ticket|
        ticket.ticket_suppliers.where(data_version: 0).each do |ts|
          all_prices << { 
            ticket_id: ticket.id,
            supplier_id: ts.supplier_id,
            price: ts.current_price,
            supplier_name: ts.supplier.name,
            ticket_name: ticket.name
          }
        end
      end
      
      cheapest = all_prices.min_by { |p| p[:price] }
      
      actual_ts = TicketSupplier.find_by(
        ticket_id: @ticket_order.ticket_id,
        supplier_id: @ticket_order.supplier_id,
        data_version: 0
      )
      actual_price = actual_ts&.current_price || @ticket_order.ticket.current_price
      actual_supplier = @ticket_order.supplier&.name || "无供应商"
      
      is_cheapest = (@ticket_order.ticket_id == cheapest[:ticket_id] && 
                     @ticket_order.supplier_id == cheapest[:supplier_id])
      
      expect(is_cheapest).to be_truthy,
        "未选择最便宜的供应商。" \
        "应选: #{cheapest[:supplier_name]}（#{cheapest[:ticket_name]}，#{cheapest[:price]}元），" \
        "实际选择: #{actual_supplier}（#{@ticket_order.ticket.name}，#{actual_price}元）"
    end
  end
  
  private
  
  def execution_state_data
    {
      attraction_name: @attraction_name,
      ticket_type: @ticket_type,
      visit_date: @visit_date.to_s,
      quantity: @quantity,
      attraction_id: @attraction&.id,
      best_price: @best_price
    }
  end
  
  def restore_from_state(data)
    @attraction_name = data['attraction_name']
    @ticket_type = data['ticket_type']
    @visit_date = Date.parse(data['visit_date'])
    @quantity = data['quantity']
    @best_price = data['best_price']
    @attraction = Attraction.find_by(id: data['attraction_id']) if data['attraction_id']
    
    if @attraction
      @child_tickets = Ticket.where(
        attraction_id: @attraction.id,
        ticket_type: @ticket_type,
        data_version: 0
      )
    end
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    attraction = Attraction.find_by!(name: @attraction_name, data_version: 0)
    
    child_tickets = Ticket.where(
      attraction_id: attraction.id,
      ticket_type: @ticket_type,
      data_version: 0
    )
    
    cheapest_supplier = nil
    min_price = Float::INFINITY
    
    child_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_price
          min_price = ts.current_price
          cheapest_supplier = ts
        end
      end
    end
    
    raise "未找到可用的儿童票供应商" unless cheapest_supplier
    
    TicketOrder.create!(
      ticket_id: cheapest_supplier.ticket_id,
      supplier_id: cheapest_supplier.supplier_id,
      user_id: user.id,
      contact_phone: '13800138000',
      visit_date: @visit_date,
      quantity: @quantity,
      total_price: cheapest_supplier.current_price * @quantity,
      status: 'pending',
      notes: '儿童票订单'
    )
  end
end
