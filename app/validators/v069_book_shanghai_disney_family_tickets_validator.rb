# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例69: 预订后天上海迪士尼家庭票（2成人+1儿童，选最优惠组合）
# 
# 任务描述:
#   Agent 需要为一家三口（2成人+1儿童）预订上海迪士尼门票，
#   对比单独购买和家庭套票价格，选择最优惠方案并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"上海迪士尼乐园"景点
#   2. 需要识别成人票和儿童票
#   3. 需要计算组合方案价格（2成人+1儿童单独购买 vs 家庭套票）
#   4. 需要对比多个供应商的价格
#   5. 需要选择最优惠的购买方案
#   6. 可能需要创建2个订单（成人票+儿童票）或1个套票订单
#   ❌ 不能一次性提供：需要先搜索→对比票种→计算总价→选择方案
# 
# 评分标准:
#   - 订单已创建且数量正确 (20分)
#   - 景点正确（上海迪士尼乐园）(15分)
#   - 成人票数量=2张 (15分)
#   - 儿童票数量=1张 (15分)
#   - 游玩日期正确（后天）(10分)
#   - 选择了最优惠的供应商组合 (25分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v069_book_shanghai_disney_family_tickets_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V069BookShanghaiDisneyFamilyTicketsValidator < BaseValidator
  self.validator_id = 'v069_book_shanghai_disney_family_tickets_validator'
  self.title = '预订后天上海迪士尼家庭票（2成人+1儿童，最优惠组合）'
  self.description = '为一家三口预订迪士尼门票，对比成人票和儿童票价格，选择最优惠的供应商组合'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @attraction_name = '上海迪士尼乐园'
    @visit_date = Date.current + 2.days  # 后天
    @adult_count = 2  # 2个成人
    @child_count = 1  # 1个儿童
    
    # 查找目标景点（注意：查询基线数据 data_version=0）
    @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
    
    raise "未找到景点: #{@attraction_name}" unless @attraction
    
    # 查找成人票和儿童票
    @adult_tickets = Ticket.where(
      attraction_id: @attraction.id,
      ticket_type: 'adult',
      data_version: 0
    )
    
    @child_tickets = Ticket.where(
      attraction_id: @attraction.id,
      ticket_type: 'child',
      data_version: 0
    )
    
    # 计算最优方案
    calculate_best_combination
    
    # 返回给 Agent 的任务信息
    {
      task: "请为一家三口（2成人+1儿童）预订后天（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的门票，选择最优惠的供应商组合",
      attraction_name: @attraction_name,
      visit_date: @visit_date.to_s,
      date_description: "后天（#{@visit_date.strftime('%Y年%m月%d日')}）",
      adult_count: @adult_count,
      child_count: @child_count,
      hint: "系统中有多个供应商提供成人票和儿童票，请对比价格后选择最优惠的组合方案（2成人票+1儿童票）",
      available_adult_tickets: @adult_tickets.count,
      available_child_tickets: @child_tickets.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @ticket_orders = TicketOrder.order(created_at: :desc).limit(5).to_a
      expect(@ticket_orders).not_to be_empty, "未找到任何门票订单记录"
      
      # 统计成人票和儿童票数量
      @actual_adult_count = 0
      @actual_child_count = 0
      
      @ticket_orders.each do |order|
        ticket = order.ticket
        if ticket.ticket_type == 'adult'
          @actual_adult_count += order.quantity
        elsif ticket.ticket_type == 'child'
          @actual_child_count += order.quantity
        end
      end
    end
    
    return if @ticket_orders.empty? # 如果没有订单，后续断言无法继续
    
    # 断言2: 景点正确
    add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
      @ticket_orders.each do |order|
        attraction = order.ticket.attraction
        expect(attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
      end
    end
    
    # 断言3: 成人票数量正确
    add_assertion "成人票数量正确（#{@adult_count}张）", weight: 15 do
      expect(@actual_adult_count).to eq(@adult_count),
        "成人票数量错误。期望: #{@adult_count}张, 实际: #{@actual_adult_count}张"
    end
    
    # 断言4: 儿童票数量正确
    add_assertion "儿童票数量正确（#{@child_count}张）", weight: 15 do
      expect(@actual_child_count).to eq(@child_count),
        "儿童票数量错误。期望: #{@child_count}张, 实际: #{@actual_child_count}张"
    end
    
    # 断言5: 游玩日期正确
    add_assertion "游玩日期正确（后天，#{@visit_date}）", weight: 10 do
      @ticket_orders.each do |order|
        expect(order.visit_date).to eq(@visit_date),
          "游玩日期错误。期望: #{@visit_date}（后天）, 实际: #{order.visit_date}"
      end
    end
    
    # 断言6: 选择了最优惠的供应商组合（核心评分项）
    add_assertion "选择了最优惠的供应商组合", weight: 25 do
      # 计算实际总价
      actual_total = @ticket_orders.sum(&:total_price)
      
      # 与最优方案对比（允许±10元误差，因为可能有不同的合理组合）
      best_total = @best_adult_price * @adult_count + @best_child_price * @child_count
      
      expect(actual_total).to be <= (best_total * 1.05),
        "未选择最优惠的供应商组合。" \
        "最优方案总价: #{best_total}元（成人#{@best_adult_price}元×#{@adult_count} + 儿童#{@best_child_price}元×#{@child_count}），" \
        "实际总价: #{actual_total}元"
    end
  end
  
  private
  
  # 计算最优组合方案
  def calculate_best_combination
    # 找到最便宜的成人票
    best_adult_supplier = nil
    min_adult_price = Float::INFINITY
    
    @adult_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_adult_price
          min_adult_price = ts.current_price
          best_adult_supplier = ts
        end
      end
    end
    
    # 找到最便宜的儿童票
    best_child_supplier = nil
    min_child_price = Float::INFINITY
    
    @child_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_child_price
          min_child_price = ts.current_price
          best_child_supplier = ts
        end
      end
    end
    
    @best_adult_price = min_adult_price
    @best_child_price = min_child_price
    @best_adult_supplier = best_adult_supplier
    @best_child_supplier = best_child_supplier
  end
  
  # 保存执行状态数据
  def execution_state_data
    {
      attraction_name: @attraction_name,
      visit_date: @visit_date.to_s,
      adult_count: @adult_count,
      child_count: @child_count,
      attraction_id: @attraction&.id,
      best_adult_price: @best_adult_price,
      best_child_price: @best_child_price
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @attraction_name = data['attraction_name']
    @visit_date = Date.parse(data['visit_date'])
    @adult_count = data['adult_count']
    @child_count = data['child_count']
    @best_adult_price = data['best_adult_price']
    @best_child_price = data['best_child_price']
    @attraction = Attraction.find_by(id: data['attraction_id']) if data['attraction_id']
    
    # 重新加载票种列表
    if @attraction
      @adult_tickets = Ticket.where(
        attraction_id: @attraction.id,
        ticket_type: 'adult',
        data_version: 0
      )
      @child_tickets = Ticket.where(
        attraction_id: @attraction.id,
        ticket_type: 'child',
        data_version: 0
      )
      calculate_best_combination
    end
  end
  
  # 模拟 AI Agent 操作：预订上海迪士尼家庭票
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找目标景点
    attraction = Attraction.find_by!(name: @attraction_name, data_version: 0)
    
    # 3. 查找成人票和儿童票
    adult_tickets = Ticket.where(
      attraction_id: attraction.id,
      ticket_type: 'adult',
      data_version: 0
    )
    
    child_tickets = Ticket.where(
      attraction_id: attraction.id,
      ticket_type: 'child',
      data_version: 0
    )
    
    # 4. 找到最便宜的成人票供应商
    best_adult_supplier = nil
    min_adult_price = Float::INFINITY
    
    adult_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_adult_price
          min_adult_price = ts.current_price
          best_adult_supplier = ts
        end
      end
    end
    
    # 5. 找到最便宜的儿童票供应商
    best_child_supplier = nil
    min_child_price = Float::INFINITY
    
    child_tickets.each do |ticket|
      ticket.ticket_suppliers.where(data_version: 0).each do |ts|
        if ts.current_price < min_child_price
          min_child_price = ts.current_price
          best_child_supplier = ts
        end
      end
    end
    
    raise "未找到可用的成人票供应商" unless best_adult_supplier
    raise "未找到可用的儿童票供应商" unless best_child_supplier
    
    # 6. 创建成人票订单（2张）
    adult_order = TicketOrder.create!(
      ticket_id: best_adult_supplier.ticket_id,
      supplier_id: best_adult_supplier.supplier_id,
      user_id: user.id,
      contact_phone: '13800138000',
      visit_date: @visit_date,
      quantity: @adult_count,
      total_price: best_adult_supplier.current_price * @adult_count,
      status: 'pending',
      notes: '家庭票-成人'
    )
    
    # 7. 创建儿童票订单（1张）
    child_order = TicketOrder.create!(
      ticket_id: best_child_supplier.ticket_id,
      supplier_id: best_child_supplier.supplier_id,
      user_id: user.id,
      contact_phone: '13800138000',
      visit_date: @visit_date,
      quantity: @child_count,
      total_price: best_child_supplier.current_price * @child_count,
      status: 'pending',
      notes: '家庭票-儿童'
    )
    
    # 返回操作信息
    {
      action: 'create_family_tickets',
      adult_order_id: adult_order.id,
      child_order_id: child_order.id,
      attraction_name: attraction.name,
      adult_ticket_name: adult_order.ticket.name,
      child_ticket_name: child_order.ticket.name,
      adult_price: best_adult_supplier.current_price,
      child_price: best_child_supplier.current_price,
      adult_count: @adult_count,
      child_count: @child_count,
      total_price: adult_order.total_price + child_order.total_price,
      visit_date: @visit_date.to_s,
      user_email: user.email
    }
  end
end
