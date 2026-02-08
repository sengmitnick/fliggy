# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例73: 预订7天后深圳欢乐谷成人票（2张，最便宜）
module V051V100
  class V073BookChengduHappyValleyNightTicketValidator < BaseValidator
    self.validator_id = 'v073_book_chengdu_happy_valley_night_ticket_validator'
    self.task_id = 'aa530ff5-edb9-4be1-866c-1ede13516233'
    self.title = '预订7天后深圳欢乐谷成人票（2张，最便宜）'
    self.description = '预订深圳欢乐谷成人票并选择最便宜供应商'
    self.timeout_seconds = 240
  
    def prepare
      @attraction_name = '深圳欢乐谷'
      @ticket_type = 'adult'
      @visit_date = Date.current + 7.days
      @quantity = 2
    
      @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
      raise "未找到景点: #{@attraction_name}" unless @attraction
    
      @adult_tickets = Ticket.where(
        attraction_id: @attraction.id,
        ticket_type: @ticket_type,
        data_version: 0
      )
    
      # 判断是否为周末（周六=6, 周日=0）
      @is_weekend = [0, 6].include?(@visit_date.wday)
      @date_type_keyword = @is_weekend ? '周末' : '平日'
    
      # 过滤出对应的票种（平日或周末）
      @applicable_tickets = @adult_tickets.select { |t| t.name.include?(@date_type_keyword) }
    
      # 如果没有区分平日/周末的票，则使用所有成人票
      @applicable_tickets = @adult_tickets if @applicable_tickets.empty?
    
      cheapest_supplier = nil
      min_price = Float::INFINITY
    
      @applicable_tickets.each do |ticket|
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
      date_desc = "#{days_until_visit}天后"
    
      {
        task: "请预订#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}#{@is_weekend ? '，周末' : ''}）#{@attraction_name}的成人票（2张），选择最便宜的供应商",
        attraction_name: @attraction_name,
        ticket_type: "成人票",
        visit_date: @visit_date.to_s,
        date_description: "#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）",
        date_type: @date_type_keyword,
        quantity: @quantity,
        hint: "系统中有多个供应商提供成人票，请对比价格后选择最便宜的#{@date_type_keyword}票",
        available_adult_tickets_count: @applicable_tickets.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 20 do
        all_ticket_orders = TicketOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_ticket_orders).not_to be_empty, "未找到任何TicketOrder记录"
        @ticket_order = all_ticket_orders.first
        # Replaced by expect(all_ticket_orders).not_to be_empty above, "未找到任何门票订单记录"
      end
    
      return unless @ticket_order
    
      add_assertion "景点正确（#{@attraction_name}）", weight: 20 do
        ticket = @ticket_order.ticket
        attraction = ticket.attraction
      
        expect(attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
      end
    
      add_assertion "票种正确（成人票）", weight: 25 do
        ticket = @ticket_order.ticket
      
        expect(ticket.ticket_type).to eq(@ticket_type),
          "票种错误。期望: 成人票(adult), 实际: #{ticket.ticket_type}"
      end
    
      add_assertion "游玩日期正确（7天后，#{@visit_date}）", weight: 10 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "游玩日期错误。期望: #{@visit_date}（7天后）, 实际: #{@ticket_order.visit_date}"
      end
    
      add_assertion "选择了最便宜的供应商", weight: 25 do
        # 判断游玩日期是否为周末
        is_weekend = [0, 6].include?(@visit_date.wday)
        date_type_keyword = is_weekend ? '周末' : '平日'
      
        # 过滤出适用的票种（平日或周末）
        applicable_tickets = @adult_tickets.select { |t| t.name.include?(date_type_keyword) }
        # 如果没有区分平日/周末的票，则使用所有成人票
        applicable_tickets = @adult_tickets if applicable_tickets.empty?
      
        all_prices = []
        applicable_tickets.each do |ticket|
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
          "未选择最便宜的供应商（#{date_type_keyword}票中）。" \
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
        best_price: @best_price,
        is_weekend: @is_weekend,
        date_type_keyword: @date_type_keyword
      }
    end
  
    def restore_from_state(data)
      @attraction_name = data['attraction_name']
      @ticket_type = data['ticket_type']
      @visit_date = Date.parse(data['visit_date'])
      @quantity = data['quantity']
      @best_price = data['best_price']
      @is_weekend = data['is_weekend']
      @date_type_keyword = data['date_type_keyword']
      @attraction = Attraction.find_by(id: data['attraction_id']) if data['attraction_id']
    
      if @attraction
        @adult_tickets = Ticket.where(
          attraction_id: @attraction.id,
          ticket_type: @ticket_type,
          data_version: 0
        )
        # 重新过滤适用票种
        @applicable_tickets = @adult_tickets.select { |t| t.name.include?(@date_type_keyword) }
        @applicable_tickets = @adult_tickets if @applicable_tickets.empty?
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
    
      # 判断是否为周末，过滤适用票种
      is_weekend = [0, 6].include?(@visit_date.wday)
      date_type_keyword = is_weekend ? '周末' : '平日'
      applicable_tickets = adult_tickets.select { |t| t.name.include?(date_type_keyword) }
      applicable_tickets = adult_tickets if applicable_tickets.empty?
    
      cheapest_supplier = nil
      min_price = Float::INFINITY
    
      applicable_tickets.each do |ticket|
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
end
