# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例71: 预订本周末广州长隆野生动物世界成人票（4张）
class V071BookGuangzhouChimelongStudentTicketValidator < BaseValidator
  self.validator_id = 'v071_book_guangzhou_chimelong_student_ticket_validator'
  self.task_id = '5349ccad-e036-400c-a6e1-ffce23767534'
  self.title = '预订本周末广州长隆野生动物世界成人票（4张，最便宜）'
  self.description = '为4位成人预订本周末的长隆野生动物世界门票并选择最便宜供应商'
  self.timeout_seconds = 240
  
  def prepare
    @attraction_name = '广州长隆野生动物世界'
    @ticket_type = 'adult'
    @quantity = 4
    
    today = Date.current
    days_until_saturday = (6 - today.wday) % 7
    days_until_saturday = 7 if days_until_saturday == 0 && today.wday != 6
    @visit_date = today + days_until_saturday.days
    
    if today.saturday?
      @visit_date = today
    elsif today.sunday?
      @visit_date = today + 6.days
    end
    
    @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
    raise "未找到景点: #{@attraction_name}" unless @attraction
    
    @adult_tickets = Ticket.where(attraction_id: @attraction.id, ticket_type: @ticket_type, data_version: 0)
    
    cheapest_supplier = nil
    min_price = Float::INFINITY
    
    @adult_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_price
          min_price = ts.current_price
          cheapest_supplier = ts
        end
      end
    end
    
    @best_ticket_supplier = cheapest_supplier
    @best_price = min_price
    
    {
      task: "请为4位成人预订本周末（#{@visit_date.strftime('%Y年%m月%d日')}，周#{['日','一','二','三','四','五','六'][@visit_date.wday]}）#{@attraction_name}的成人票，选择最便宜的供应商",
      attraction_name: @attraction_name,
      ticket_type: "成人票",
      visit_date: @visit_date.to_s,
      date_description: "本周末（#{@visit_date.strftime('%Y年%m月%d日')}，周#{['日','一','二','三','四','五','六'][@visit_date.wday]}）",
      quantity: @quantity,
      hint: "系统中有多个供应商提供成人票。请对比价格后选择最便宜的",
      available_adult_tickets_count: @adult_tickets.count,
      weekend_note: "本周末为周六（#{@visit_date}）"
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
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
    
    add_assertion "票种正确（成人票）", weight: 20 do
      ticket = @ticket_order.ticket
      
      expect(ticket.ticket_type).to eq(@ticket_type),
        "票种错误。期望: 成人票(adult), 实际: #{ticket.ticket_type}"
    end
    
    add_assertion "数量正确（#{@quantity}张）", weight: 10 do
      expect(@ticket_order.quantity).to eq(@quantity),
        "数量错误。期望: #{@quantity}张, 实际: #{@ticket_order.quantity}张"
    end
    
    add_assertion "游玩日期为本周末（周六或周日）", weight: 10 do
      is_weekend = @ticket_order.visit_date.saturday? || @ticket_order.visit_date.sunday?
      
      days_diff = (@ticket_order.visit_date - Date.current).to_i
      is_this_or_next_weekend = days_diff >= 0 && days_diff <= 14
      
      expect(is_weekend && is_this_or_next_weekend).to be_truthy,
        "游玩日期不是周末。期望: 周六或周日（本周或下周末），实际: #{@ticket_order.visit_date.strftime('%Y年%m月%d日')}（周#{['日','一','二','三','四','五','六'][@ticket_order.visit_date.wday]}）"
    end
    
    add_assertion "选择了最便宜的供应商", weight: 20 do
      all_prices = []
      @adult_tickets.each do |ticket|
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
      @adult_tickets = Ticket.where(
        attraction_id: @attraction.id,
        ticket_type: @ticket_type,
        data_version: 0
      )
    end
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    attraction = Attraction.find_by!(name: @attraction_name, data_version: 0)
    
    adult_tickets = Ticket.where(
      attraction_id: attraction.id,
      ticket_type: @ticket_type,
      data_version: 0
    )
    
    cheapest_supplier = nil
    min_price = Float::INFINITY
    
    adult_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_price
          min_price = ts.current_price
          cheapest_supplier = ts
        end
      end
    end
    
    raise "未找到可用的成人票供应商" unless cheapest_supplier
    
    TicketOrder.create!(
      ticket_id: cheapest_supplier.ticket_id,
      supplier_id: cheapest_supplier.supplier_id,
      user_id: user.id,
      contact_phone: '13800138000',
      visit_date: @visit_date,
      quantity: @quantity,
      total_price: cheapest_supplier.current_price * @quantity,
      status: 'pending',
      notes: '成人票订单'
    )
  end
end