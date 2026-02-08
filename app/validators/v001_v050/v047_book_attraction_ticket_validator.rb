# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例47: 预订明天深圳欢乐港湾成人票（1张，最便宜供应商）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳欢乐港湾的门票，
#   找到成人票中价格最便宜的供应商并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"深圳欢乐港湾"景点（从6个景点中找到）
#   2. 需要选择成人票类型（排除儿童票）
#   3. 需要对比多个供应商的价格（4个供应商）
#   4. 需要选择价格最低的供应商
#   5. 需要填写游玩日期（明天）和数量（1张）
#   6. 需要区分平日票和周末票（根据游玩日期）
#   ❌ 不能一次性提供：需要先搜索景点→选择票种→对比供应商→预订
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 订单属于张三（用户+联系电话） (15分)
#   - 景点正确（深圳欢乐港湾）(15分)
#   - 票种正确（成人票）(15分)
#   - 游玩日期正确（明天）(10分)
#   - 数量正确（1张）(10分)
#   - 选择了最便宜的供应商 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v047_book_attraction_ticket_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V047BookAttractionTicketValidator < BaseValidator
    self.validator_id = 'v047_book_attraction_ticket_validator'
    self.task_id = '72f0aacf-7273-46bb-a334-35194205d1d1'
    self.title = '帮张三预订明天深圳欢乐港湾成人票1张（最便宜供应商）'
    self.description = 'Agent 需要为张三预订明天深圳欢乐港湾的成人门票1张，在多个供应商中选择最便宜的'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @attraction_name = '深圳欢乐港湾'
      @ticket_type = 'adult'
      @visit_date = Date.current + 1.day  # 明天
      @quantity = 1
    
      # 查找目标景点（注意：查询基线数据 data_version=0）
      @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
    
      raise "未找到景点: #{@attraction_name}" unless @attraction
    
      # 查找成人票
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
    
      # 查找适用票种中最便宜的供应商（通过 ticket_suppliers 关联）
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
    
      # 返回给 Agent 的任务信息
      {
        task: "请预订明天（#{@visit_date.strftime('%Y年%m月%d日')}#{@is_weekend ? '，周末' : ''}）#{@attraction_name}的成人票1张，选择最便宜的供应商",
        attraction_name: @attraction_name,
        ticket_type: "成人票",
        visit_date: @visit_date.to_s,
        date_description: "明天（#{@visit_date.strftime('%Y年%m月%d日')}）",
        date_type: @date_type_keyword,
        quantity: @quantity,
        hint: "系统中有多个供应商提供该景点门票，请对比价格后选择最便宜的#{@date_type_keyword}票",
        available_attractions_count: Attraction.where(data_version: 0).count,
        ticket_types_count: @applicable_tickets.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 15 do
        all_ticket_orders = TicketOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_ticket_orders).not_to be_empty, "未找到任何TicketOrder记录"
        @ticket_order = all_ticket_orders.first
        # Replaced by expect(all_ticket_orders).not_to be_empty above, "未找到任何门票订单记录"
      end
    
      return unless @ticket_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单属于张三（用户+联系电话）
      add_assertion "订单属于张三（用户+联系电话）", weight: 15 do
        expected_user = User.find_by(email: 'demo@travel01.com', data_version: 0)
        expect(expected_user).not_to be_nil, "未找到用户张三（demo@travel01.com）"
        
        expected_contact = expected_user.contacts.find_by(name: '张三', data_version: 0)
        expect(expected_contact).not_to be_nil, "未找到联系人张三在 demo_user.contacts 中"
        
        expect(@ticket_order.user_id).to eq(expected_user.id),
          "订单用户错误。期望: 张三（#{expected_user.email}），实际: #{@ticket_order.user&.email || '无用户'}"
        
        expect(@ticket_order.contact_phone).to eq(expected_contact.phone),
          "联系电话错误。期望: #{expected_contact.phone}（demo_user数据），实际: #{@ticket_order.contact_phone}"
      end
    
      # 断言3: 景点正确
      add_assertion "景点正确", weight: 15 do
        ticket = @ticket_order.ticket
        attraction = ticket.attraction
      
        expect(attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
      end
    
      # 断言4: 票种正确（成人票）
      add_assertion "票种正确（成人票）", weight: 15 do
        ticket = @ticket_order.ticket
      
        expect(ticket.ticket_type).to eq(@ticket_type),
          "票种错误。期望: 成人票(adult), 实际: #{ticket.ticket_type}"
      end
    
      # 断言5: 游玩日期正确
      add_assertion "游玩日期正确", weight: 10 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "游玩日期错误。期望: #{@visit_date}, 实际: #{@ticket_order.visit_date}"
      end
    
      # 断言6: 数量正确（1张）
      add_assertion "数量正确（1张）", weight: 10 do
        expect(@ticket_order.quantity).to eq(@quantity),
          "数量错误。期望: #{@quantity}张, 实际: #{@ticket_order.quantity}张"
      end
    
      # 断言7: 选择了最便宜的供应商（核心评分项）
      add_assertion "选择了最便宜的供应商", weight: 20 do
        # 判断游玩日期是否为周末
        is_weekend = [0, 6].include?(@visit_date.wday)
        date_type_keyword = is_weekend ? '周末' : '平日'
      
        # 过滤出适用的票种（平日或周末）
        applicable_tickets = @adult_tickets.select { |t| t.name.include?(date_type_keyword) }
        # 如果没有区分平日/周末的票，则使用所有成人票
        applicable_tickets = @adult_tickets if applicable_tickets.empty?
      
        # 获取适用票种的所有供应商价格
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
      
        # 找到最低价格
        cheapest = all_prices.min_by { |p| p[:price] }
      
        # 获取实际订单的ticket_supplier记录
        actual_ts = TicketSupplier.find_by(
          ticket_id: @ticket_order.ticket_id,
          supplier_id: @ticket_order.supplier_id,
          data_version: 0
        )
        actual_price = actual_ts&.current_price || @ticket_order.ticket.current_price
        actual_supplier = @ticket_order.supplier&.name || "无供应商"
      
        # 验证是否选择了最优组合
        is_cheapest = (@ticket_order.ticket_id == cheapest[:ticket_id] && 
                       @ticket_order.supplier_id == cheapest[:supplier_id])
      
        expect(is_cheapest).to be_truthy,
          "未选择最便宜的供应商（#{date_type_keyword}票中）。" \
          "应选: #{cheapest[:supplier_name]}（#{cheapest[:ticket_name]}，#{cheapest[:price]}元），" \
          "实际选择: #{actual_supplier}（#{@ticket_order.ticket.name}，#{actual_price}元）"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        attraction_name: @attraction_name,
        ticket_type: @ticket_type,
        visit_date: @visit_date.to_s,
        quantity: @quantity,
        attraction_id: @attraction&.id,
        best_ticket_supplier_id: @best_ticket_supplier&.id,
        is_weekend: @is_weekend,
        date_type_keyword: @date_type_keyword
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @attraction_name = data['attraction_name']
      @ticket_type = data['ticket_type']
      @visit_date = Date.parse(data['visit_date'])
      @quantity = data['quantity']
      @attraction = Attraction.find_by(id: data['attraction_id']) if data['attraction_id']
      @best_ticket_supplier = TicketSupplier.find_by(id: data['best_ticket_supplier_id']) if data['best_ticket_supplier_id']
      @is_weekend = data['is_weekend']
      @date_type_keyword = data['date_type_keyword']
    
      # 重新加载成人票列表
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
  
    # 模拟 AI Agent 操作：预订深圳欢乐港湾最便宜的成人票
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1.5 获取联系人信息
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
    
      # 2. 查找目标景点
      attraction = Attraction.find_by!(name: @attraction_name, data_version: 0)
    
      # 3. 查找成人票
      adult_tickets = Ticket.where(
        attraction_id: attraction.id,
        ticket_type: @ticket_type,
        data_version: 0
      )
    
      # 4. 判断是否为周末，过滤适用票种
      is_weekend = [0, 6].include?(@visit_date.wday)
      date_type_keyword = is_weekend ? '周末' : '平日'
      applicable_tickets = adult_tickets.select { |t| t.name.include?(date_type_keyword) }
      applicable_tickets = adult_tickets if applicable_tickets.empty?
    
      # 5. 找到价格最低的供应商
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
    
      raise "未找到可用的门票供应商" unless cheapest_supplier
    
      # 6. 创建门票订单
      ticket_order = TicketOrder.create!(
        ticket_id: cheapest_supplier.ticket_id,
        supplier_id: cheapest_supplier.supplier_id,
        user_id: user.id,
        contact_phone: contact.phone,
        visit_date: @visit_date,
        quantity: @quantity,
        total_price: cheapest_supplier.current_price * @quantity,
        status: 'pending',
        notes: '测试订单'
      )
    
      # 返回操作信息
      {
        action: 'create_ticket_order',
        order_id: ticket_order.id,
        order_number: ticket_order.order_number,
        attraction_name: attraction.name,
        ticket_name: ticket_order.ticket.name,
        supplier_name: ticket_order.supplier&.name,
        price: cheapest_supplier.current_price,
        visit_date: @visit_date.to_s,
        quantity: @quantity,
        total_price: ticket_order.total_price
      }
    end
  end
end
