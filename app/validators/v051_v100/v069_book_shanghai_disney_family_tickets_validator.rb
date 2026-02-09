# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例69: 张三一家预订后天上海迪士尼门票（2成人+1儿童，最便宜）
# 
# 任务描述:
#   Agent 需要为张三一家预订后天的上海迪士尼乐园门票。
#   张三一家包括：张三（成人男）、王芳（成人女）、小明（儿童）
#   由于系统不支持家庭套票，需要创建2个独立订单：
#   - 1个成人票订单（数量2张，游客：张三、王芳）
#   - 1个儿童票订单（数量1张，游客：小明）
#   并选择最便宜的供应商组合
# 
# 复杂度分析:
#   1. 需要搜索"上海迪士尼乐园"景点
#   2. 需要理解系统不支持家庭套票，必须分别预订
#   3. 需要创建2个独立订单（成人票订单 + 儿童票订单）
#   4. 需要对比供应商价格，选择最优组合
#   5. 需要填写正确的游玩日期（后天）
#   ❌ 不能一次性提供：需要先搜索→识别票种→对比价格→创建2个订单
# 
# 评分标准:
#   - 创建了2个订单（成人票+儿童票）(20分)
#   - 景点正确（上海迪士尼乐园）(15分)
#   - 成人票数量正确（2张）(15分)
#   - 儿童票数量正确（1张）(15分)
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
module V051V100
  class V069BookShanghaiDisneyFamilyTicketsValidator < BaseValidator
    self.validator_id = 'v069_book_shanghai_disney_family_tickets_validator'
    self.task_id = '01352bcb-f7ff-4891-a072-114e6565b87d'
    self.title = '张三一家预订后天上海迪士尼门票（2成人+1儿童，最便宜）'
    self.description = '为张三一家（张三、王芳、小明）预订迪士尼门票，通过2个订单实现，选择最便宜的供应商'
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
    
      # 查询出行人（demo_user 数据） - 用于游客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 查询联系人（demo_user 数据） - 用于联系电话验证
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @wangfang_contact = user.contacts.find_by!(name: '王芳', data_version: 0)
      
      # 验证预期值：联系人可以是张三或王芳（多选一）
      @valid_contact_names = ['张三', '王芳']
      @valid_contact_phones = {
        '张三' => @zhangsan_contact.phone,
        '王芳' => @wangfang_contact.phone
      }
      @expected_passenger_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
    
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
        task: "请为张三一家预订后天（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的门票，选择最优惠的供应商组合",
        family_members: "张三（成人男）、王芳（成人女）、小明（儿童）",
        attraction_name: @attraction_name,
        visit_date: @visit_date.to_s,
        date_description: "后天（#{@visit_date.strftime('%Y年%m月%d日')}）",
        adult_count: @adult_count,
        child_count: @child_count,
        hint: "系统不支持家庭套票，需要分别购买：2张成人票（游客：张三、王芳）和1张儿童票（游客：小明）。请对比供应商价格后选择最优惠的组合方案",
        available_adult_tickets: @adult_tickets.count,
        available_child_tickets: @child_tickets.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 创建了成人票和儿童票订单
      add_assertion "创建了成人票和儿童票订单", weight: 20 do
        # 查询当前会话的订单（按景点和 data_version 筛选）
        all_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何#{@attraction_name}的门票订单记录"
      
        # 只保留成人票和儿童票订单（排除其他类型）
        @all_ticket_orders = all_orders.select { |o| ['adult', 'child'].include?(o.ticket.ticket_type) }
      
        expect(@all_ticket_orders).not_to be_empty,
          "未找到成人票或儿童票订单（找到#{all_orders.size}个订单，但都不是成人票/儿童票）"
      
        # 分离成人票和儿童票（不管日期）
        all_adult_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
        all_child_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'child' }
      
        expect(all_adult_orders).not_to be_empty, "未找到成人票订单"
        expect(all_child_orders).not_to be_empty, "未找到儿童票订单"
      
        # 验证订单是否为后天（使用 .by_date 作用域）
        @adult_orders = all_adult_orders.select { |o| o.visit_date == @visit_date }
        @child_orders = all_child_orders.select { |o| o.visit_date == @visit_date }
      
        # 如果日期不对，给出详细提示
        if @adult_orders.empty?
          actual_dates = all_adult_orders.map(&:visit_date).uniq.join(', ')
          raise "成人票订单日期错误。期望: #{@visit_date}（后天）, 实际: #{actual_dates}"
        end
      
        if @child_orders.empty?
          actual_dates = all_child_orders.map(&:visit_date).uniq.join(', ')
          raise "儿童票订单日期错误。期望: #{@visit_date}（后天）, 实际: #{actual_dates}"
        end
      
        # 确保至少有1个成人票订单和1个儿童票订单
        expect(@adult_orders.size).to be >= 1, "未找到后天的成人票订单"
        expect(@child_orders.size).to be >= 1, "未找到后天的儿童票订单"
      end
    
      return if @all_ticket_orders.nil? || @all_ticket_orders.empty?
    
      # 断言2: 景点正确（上海迪士尼乐园）
      add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
        @all_ticket_orders.each do |order|
          actual_name = order.ticket.attraction.name
          expect(actual_name).to eq(@attraction_name),
            "景点错误。订单ID: #{order.id}, 期望: #{@attraction_name}, 实际: #{actual_name}"
        end
      end
    
      # 断言3: 成人票数量正确（2张）
      add_assertion "成人票总数量正确（2张）", weight: 15 do
        total_adult_quantity = @adult_orders.sum(&:quantity)
      
        expect(total_adult_quantity).to eq(@adult_count),
          "成人票总数量错误。期望: #{@adult_count}张, 实际: #{total_adult_quantity}张（#{@adult_orders.size}个订单）"
      end
    
      # 断言4: 儿童票数量正确（1张）
      add_assertion "儿童票总数量正确（1张）", weight: 15 do
        total_child_quantity = @child_orders.sum(&:quantity)
      
        expect(total_child_quantity).to eq(@child_count),
          "儿童票总数量错误。期望: #{@child_count}张, 实际: #{total_child_quantity}张（#{@child_orders.size}个订单）"
      end
    
      # 断言5: 游玩日期正确（后天）
      add_assertion "游玩日期正确（后天: #{@visit_date}）", weight: 10 do
        @all_ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "订单ID: #{order.id}, 游玩日期错误。期望: #{@visit_date}（后天）, 实际: #{order.visit_date}"
        end
      end
    
      # 断言6: 选择了最优惠的供应商组合
      add_assertion "选择了最优惠的供应商组合（总价#{@best_total_price}元）", weight: 25 do
        # 计算实际总价
        actual_total = @all_ticket_orders.sum { |o| o.ticket.price * o.quantity }
      
        # 允许价格误差（由于浮点数精度）
        price_tolerance = 0.01
      
        expect(actual_total).to be_within(price_tolerance).of(@best_total_price),
          "供应商组合不是最优。期望最低总价: #{@best_total_price}元，实际总价: #{actual_total}元\n" \
          "最优方案: 成人票(#{@best_adult_ticket.supplier_name} - #{@best_adult_ticket.price}元) + " \
          "儿童票(#{@best_child_ticket.supplier_name} - #{@best_child_ticket.price}元)"
      
        # 验证实际选择的供应商
        adult_supplier = @adult_orders.first.ticket.supplier_name
        child_supplier = @child_orders.first.ticket.supplier_name
      
        expect(adult_supplier).to eq(@best_adult_ticket.supplier_name),
          "成人票供应商不是最优。期望: #{@best_adult_ticket.supplier_name}, 实际: #{adult_supplier}"
      
        expect(child_supplier).to eq(@best_child_ticket.supplier_name),
          "儿童票供应商不是最优。期望: #{@best_child_ticket.supplier_name}, 实际: #{child_supplier}"
      end
    end
  
    private
  
    # 计算最优供应商组合
    def calculate_best_combination
      # 找到最便宜的成人票
      @best_adult_ticket = @adult_tickets.order(:price).first
      raise "未找到成人票数据" unless @best_adult_ticket
    
      # 找到最便宜的儿童票
      @best_child_ticket = @child_tickets.order(:price).first
      raise "未找到儿童票数据" unless @best_child_ticket
    
      # 计算最优总价
      @best_total_price = (@best_adult_ticket.price * @adult_count) + 
                          (@best_child_ticket.price * @child_count)
    end
  end
end
