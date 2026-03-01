# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例72: 给张三预订5天后杭州西湖免费门票（成人票）
# 
# 任务描述:
#   Agent 需要为张三预订5天后的杭州西湖免费门票。
#   注意：西湖门票免费，但需要预约。
#   乘客：张三（成人）
# 
# 复杂度分析:
#   1. 需要搜索"西湖"景点（杭州地区）
#   2. 需要识别免费门票（价格为0或名称包含"免费"）
#   3. 需要填写正确的游玩日期（5天后）
#   4. 需要填写乘客信息（张三）
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 景点正确（西湖）(15分)
#   - 票种正确（免费成人票）(20分)
#   - 游玩日期正确（5天后）(5分)
#   - 联系电话正确（张三的电话）(10分)
#   - 乘客信息正确（张三）(10分)
#   - 门票为免费（价格为0）(20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v072_book_hangzhou_west_lake_free_ticket_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V072BookHangzhouWestLakeFreeTicketValidator < BaseValidator
    self.validator_id = 'v072_book_hangzhou_west_lake_free_ticket_validator'
    self.task_id = 'ae944d4f-9005-4e54-bf95-adf32269ccdf'
    self.title = '给张三预订5天后杭州西湖免费门票（成人票）'
    self.description = '给张三预订5天后杭州西湖免费门票（成人票）'
    self.timeout_seconds = 240
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      # 查询成人乘客张三
      @adult_passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      @attraction_name = '西湖'
      @ticket_type = 'adult'
      @visit_date = Date.current + 5.days
      @quantity = 1
    
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
    
      # 过滤出免费门票
      @applicable_tickets = @adult_tickets.select { |t| t.name.include?('免费') || t.current_price == 0 }
    
      # 如果没有找到免费票，使用所有成人票
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
      date_desc = case days_until_visit
      when 0 then "今天"
      when 1 then "明天"
      when 2 then "后天"
      else "#{days_until_visit}天后"
      end
    
      {
        task: "请为张三预订#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的免费门票（成人票）",
        passenger: "张三",
        attraction_name: @attraction_name,
        ticket_type: "成人票（免费）",
        visit_date: @visit_date.to_s,
        date_description: "#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）",
        date_type: @date_type_keyword,
        quantity: @quantity,
        hint: "西湖门票免费，但需要预约。请选择免费的成人票。",
        available_tickets_count: @applicable_tickets.count
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
    
      add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
        ticket = @ticket_order.ticket
        attraction = ticket.attraction
      
        expect(attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
      end
    
      add_assertion "票种正确（免费成人票）", weight: 20 do
        ticket = @ticket_order.ticket
      
        expect(ticket.ticket_type).to eq(@ticket_type),
          "票种错误。期望: 成人票(adult), 实际: #{ticket.ticket_type}"
      end
    
      add_assertion "游玩日期正确（5天后，#{@visit_date}）", weight: 5 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "游玩日期错误。期望: #{@visit_date}（5天后）, 实际: #{@ticket_order.visit_date}"
      end
    
      add_assertion "联系电话正确（张三的电话）", weight: 10 do
        expect(@ticket_order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（张三），实际: #{@ticket_order.contact_phone}"
      end
    
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@ticket_order.passenger_ids).to be_present, "未填写乘客信息"
        expect(@ticket_order.passenger_ids.size).to eq(1),
          "乘客数量错误。期望: 1位，实际: #{@ticket_order.passenger_ids&.size || 0}位"
        
        passenger_name = Passenger.find_by(id: @ticket_order.passenger_ids.first, data_version: 0)&.name
        expect(passenger_name).to eq('张三'),
          "乘客信息错误。期望: 张三，实际: #{passenger_name}"
      end
    
      add_assertion "门票为免费（价格为0）", weight: 20 do
        ticket = @ticket_order.ticket
      
        # 过滤出免费门票
        applicable_tickets = @adult_tickets.select { |t| t.name.include?('免费') || t.current_price == 0 }
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
      
        is_free = (cheapest[:price] == 0)
      
        expect(is_cheapest).to be_truthy,
          "未选择免费门票（价格为0的票）。" \
          "应选: #{cheapest[:supplier_name]}（#{cheapest[:ticket_name]}，#{cheapest[:price]}元），" \
          "实际选择: #{actual_supplier}（#{@ticket_order.ticket.name}，#{actual_price}元）"
        
        expect(is_free).to be_truthy,
          "门票不是免费的。期望价格: 0元，实际价格: #{cheapest[:price]}元"
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
        # 重新过滤免费门票
        @applicable_tickets = @adult_tickets.select { |t| t.name.include?('免费') || t.current_price == 0 }
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
    
      # 过滤出免费门票
      applicable_tickets = adult_tickets.select { |t| t.name.include?('免费') || t.current_price == 0 }
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
    
      raise "未找到可用的免费门票供应商" unless cheapest_supplier
    
      # 查询成人乘客张三
      adult_passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      TicketOrder.create!(
        ticket_id: cheapest_supplier.ticket_id,
        supplier_id: cheapest_supplier.supplier_id,
        user_id: user.id,
        contact_phone: adult_passenger.phone,
        passenger_ids: [adult_passenger.id],
        visit_date: @visit_date,
        quantity: @quantity,
        total_price: cheapest_supplier.current_price * @quantity,
        status: 'pending',
        notes: '免费成人票订单',
        data_version: @data_version
      )
    end
    end
end