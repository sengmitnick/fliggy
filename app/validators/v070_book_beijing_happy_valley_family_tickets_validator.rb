# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例70: 预订3天后北京欢乐谷家庭套餐（2成人+1儿童，最便宜）
# 
# 任务描述:
#   Agent 需要为1个家庭（2成人+1儿童）预订3天后的欢乐谷门票，
#   由于系统不支持家庭套票，需要创建2个独立订单：
#   - 1个成人票订单（数量2张）
#   - 1个儿童票订单（数量1张）
#   并选择最便宜的供应商组合
# 
# 复杂度分析:
#   1. 需要搜索"北京欢乐谷"景点
#   2. 需要理解系统不支持家庭套票，必须分别预订
#   3. 需要创建2个独立订单（成人票订单 + 儿童票订单）
#   4. 需要对比供应商价格，选择最优组合
#   5. 需要填写正确的游玩日期（3天后）
#   ❌ 不能一次性提供：需要先搜索→识别票种→对比价格→创建2个订单
# 
# 评分标准:
#   - 创建了2个订单（成人票+儿童票）(25分)
#   - 景点正确（北京欢乐谷）(15分)
#   - 成人票数量正确（2张）(10分)
#   - 儿童票数量正确（1张）(10分)
#   - 游玩日期正确（3天后）(10分)
#   - 选择了最便宜的供应商组合 (30分)
class V070BookBeijingHappyValleyFamilyTicketsValidator < BaseValidator
  self.validator_id = 'v070_book_beijing_happy_valley_family_tickets_validator'
  self.task_id = '0c17b98c-3602-4e84-9115-984ead6ebda4'
  self.title = '预订3天后北京欢乐谷家庭套餐（2成人+1儿童，最便宜）'
  self.description = '为1个家庭预订欢乐谷门票（2成人+1儿童），通过2个订单实现，选择最便宜的供应商'
  self.timeout_seconds = 240
  
  def prepare
    @attraction_name = '北京欢乐谷'
    @visit_date = Date.current + 3.days
    @adult_count = 2
    @child_count = 1
    
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
    
    days_until_visit = (@visit_date - Date.current).to_i
    date_desc = case days_until_visit
    when 0 then "今天"
    when 1 then "明天"
    when 2 then "后天"
    when 3 then "3天后"
    else "#{days_until_visit}天后"
    end
    
    {
      task: "请为1个家庭（2成人+1儿童）预订#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的门票，选择最便宜的供应商组合",
      attraction_name: @attraction_name,
      visit_date: @visit_date.to_s,
      date_description: "#{date_desc}（#{@visit_date.strftime('%Y年%m月%d日')}）",
      adult_count: @adult_count,
      child_count: @child_count,
      hint: "系统不支持家庭套票，需要分别购买：2张成人票和1张儿童票。请对比供应商价格后选择最优惠的组合方案",
      available_adult_tickets: @adult_tickets.count,
      available_child_tickets: @child_tickets.count
    }
  end
  
  def verify
    # 断言1: 必须创建2个订单（成人票订单+儿童票订单）
    add_assertion "创建了2个订单（成人票订单+儿童票订单）", weight: 25 do
      all_orders = TicketOrder.order(created_at: :desc).limit(10).to_a
      expect(all_orders).not_to be_empty, "未找到任何门票订单记录"
      
      # 找到符合条件的订单（景点正确，日期正确）
      @ticket_orders = all_orders.select do |order|
        order.ticket.attraction_id == @attraction.id && 
        order.visit_date == @visit_date
      end
      
      expect(@ticket_orders.size).to be >= 2,
        "订单数量不足。期望至少2个订单（1个成人票订单+1个儿童票订单），实际找到#{@ticket_orders.size}个订单"
      
      # 分离成人票订单和儿童票订单
      @adult_orders = @ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
      @child_orders = @ticket_orders.select { |o| o.ticket.ticket_type == 'child' }
      
      expect(@adult_orders).not_to be_empty, "未找到成人票订单"
      expect(@child_orders).not_to be_empty, "未找到儿童票订单"
      
      # 统计总数量
      @actual_adult_count = @adult_orders.sum(&:quantity)
      @actual_child_count = @child_orders.sum(&:quantity)
    end
    
    return if @ticket_orders.nil? || @ticket_orders.empty?
    
    # 断言2: 景点正确
    add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
      @ticket_orders.each do |order|
        attraction = order.ticket.attraction
        expect(attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}, 实际: #{attraction.name}"
      end
    end
    
    # 断言3: 成人票数量正确
    add_assertion "成人票数量正确（#{@adult_count}张）", weight: 10 do
      expect(@actual_adult_count).to eq(@adult_count),
        "成人票数量错误。期望: #{@adult_count}张, 实际: #{@actual_adult_count}张"
    end
    
    # 断言4: 儿童票数量正确
    add_assertion "儿童票数量正确（#{@child_count}张）", weight: 10 do
      expect(@actual_child_count).to eq(@child_count),
        "儿童票数量错误。期望: #{@child_count}张, 实际: #{@actual_child_count}张"
    end
    
    # 断言5: 游玩日期正确
    add_assertion "游玩日期正确（3天后，#{@visit_date}）", weight: 10 do
      @ticket_orders.each do |order|
        expect(order.visit_date).to eq(@visit_date),
          "游玩日期错误。期望: #{@visit_date}（3天后）, 实际: #{order.visit_date}"
      end
    end
    
    # 断言6: 选择了最便宜的供应商组合（核心评分项）
    add_assertion "选择了最优惠的供应商组合", weight: 30 do
      # 计算实际总价（只计算成人票和儿童票订单）
      actual_total = @adult_orders.sum(&:total_price) + @child_orders.sum(&:total_price)
      
      # 与最优方案对比（允许5%误差，因为可能有不同的合理组合）
      best_total = @best_adult_price * @adult_count + @best_child_price * @child_count
      
      expect(actual_total).to be <= (best_total * 1.05),
        "未选择最优惠的供应商组合。" \
        "最优方案总价: #{best_total}元（成人#{@best_adult_price}元×#{@adult_count} + 儿童#{@best_child_price}元×#{@child_count}），" \
        "实际总价: #{actual_total}元（成人票订单: #{@adult_orders.sum(&:total_price)}元 + 儿童票订单: #{@child_orders.sum(&:total_price)}元）"
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
  
  # 模拟 AI Agent 操作：预订北京欢乐谷家庭套餐
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
      notes: '家庭套餐-成人票'
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
      notes: '家庭套餐-儿童票'
    )
    
    # 返回操作信息
    {
      action: 'create_family_package_orders',
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
