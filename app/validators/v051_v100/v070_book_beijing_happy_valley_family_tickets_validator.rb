# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例70: 给张三一家预订明天北京欢乐谷门票（张三、王芳、小明，2成人+1儿童）
# 
# 任务描述:
#   Agent 需要为张三一家预订明天的北京欢乐谷门票。
#   张三一家包括：张三（成人男）、王芳（成人女）、小明（儿童）
#   由于系统不支持家庭套票，需要创建2个独立订单：
#   - 1个成人票订单（数量2张，游客：张三、王芳）
#   - 1个儿童票订单（数量1张，游客：小明）
# 
# 复杂度分析:
#   1. 需要搜索"北京欢乐谷"景点
#   2. 需要理解系统不支持家庭套票，必须分别预订
#   3. 需要创建2个独立订单（成人票订单 + 儿童票订单）
#   4. 需要填写正确的游玩日期（明天）
# 
# 评分标准:
#   - 创建了2个订单（成人票+儿童票）(20分)
#   - 景点正确（北京欢乐谷）(15分)
#   - 成人票数量正确（2张）(15分)
#   - 儿童票数量正确（1张）(15分)
#   - 游玩日期正确（明天）(10分)
#   - 联系电话正确（张三或王芳的电话）(10分)
#   - 游客名字正确（张三、王芳、小明）(15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v070_book_beijing_happy_valley_family_tickets_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V070BookBeijingHappyValleyFamilyTicketsValidator < BaseValidator
    self.validator_id = 'v070_book_beijing_happy_valley_family_tickets_validator'
    self.task_id = 'c6b1fc3d-40ad-47b8-a6db-adf4d8cb6210'
    self.title = '给张三一家预订明天北京欢乐谷门票（张三、王芳、小明，2成人+1儿童）'
    self.description = '给张三一家预订明天北京欢乐谷门票（张三、王芳、小明，2成人+1儿童）'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      @attraction_name = '北京欢乐谷'
      @visit_date = Date.current + 1.day  # 明天
      @adult_count = 2  # 2个成人
      @child_count = 1  # 1个儿童
    
      # 查找目标景点
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
    
      # 返回给 Agent 的任务信息
      {
        task: "请为张三一家预订明天（#{@visit_date.strftime('%Y年%m月%d日')}）#{@attraction_name}的门票",
        family_members: "张三（成人男）、王芳（成人女）、小明（儿童）",
        attraction_name: @attraction_name,
        visit_date: @visit_date.to_s,
        date_description: "明天（#{@visit_date.strftime('%Y年%m月%d日')}）",
        adult_count: @adult_count,
        child_count: @child_count,
        hint: "系统不支持家庭套票，需要分别购买：2张成人票（游客：张三、王芳）和1张儿童票（游客：小明）"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 创建了成人票和儿童票订单
      add_assertion "创建了成人票和儿童票订单", weight: 20 do
        all_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何#{@attraction_name}的门票订单记录"
      
        @all_ticket_orders = all_orders.select { |o| ['adult', 'child'].include?(o.ticket.ticket_type) }
        expect(@all_ticket_orders).not_to be_empty, "未找到成人票或儿童票订单"
      
        # 验证票种名称（确保是北京欢乐谷的票）
        @all_ticket_orders.each do |order|
          ticket_name = order.ticket.name
          expect(ticket_name).to include(@attraction_name),
            "订单ID: #{order.id}, 票种名称错误。期望包含: #{@attraction_name}, 实际票名: #{ticket_name}"
        end
      
        all_adult_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
        all_child_orders = @all_ticket_orders.select { |o| o.ticket.ticket_type == 'child' }
      
        expect(all_adult_orders).not_to be_empty, "未找到成人票订单"
        expect(all_child_orders).not_to be_empty, "未找到儿童票订单"
      
        @adult_orders = all_adult_orders.select { |o| o.visit_date == @visit_date }
        @child_orders = all_child_orders.select { |o| o.visit_date == @visit_date }
      
        if @adult_orders.empty?
          actual_dates = all_adult_orders.map(&:visit_date).uniq.join(', ')
          raise "成人票订单日期错误。期望: #{@visit_date}（明天）, 实际: #{actual_dates}"
        end
      
        if @child_orders.empty?
          actual_dates = all_child_orders.map(&:visit_date).uniq.join(', ')
          raise "儿童票订单日期错误。期望: #{@visit_date}（明天）, 实际: #{actual_dates}"
        end
      
        expect(@adult_orders.size).to be >= 1, "未找到明天的成人票订单"
        expect(@child_orders.size).to be >= 1, "未找到明天的儿童票订单"
      end
    
      return if @all_ticket_orders.nil? || @all_ticket_orders.empty?
    
      # 断言2: 景点正确（北京欢乐谷）
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
          "成人票总数量错误。期望: #{@adult_count}张, 实际: #{total_adult_quantity}张"
      end
    
      # 断言4: 儿童票数量正确（1张）
      add_assertion "儿童票总数量正确（1张）", weight: 15 do
        total_child_quantity = @child_orders.sum(&:quantity)
        expect(total_child_quantity).to eq(@child_count),
          "儿童票总数量错误。期望: #{@child_count}张, 实际: #{total_child_quantity}张"
      end
    
      # 断言5: 游玩日期正确（明天）
      add_assertion "游玩日期正确（明天: #{@visit_date}）", weight: 10 do
        @all_ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "订单ID: #{order.id}, 游玩日期错误。期望: #{@visit_date}（明天）, 实际: #{order.visit_date}"
        end
      end
    
      # 断言6: 联系电话正确
      add_assertion "联系电话正确（张三或王芳的电话）", weight: 10 do
        @all_ticket_orders.each do |order|
          actual_contact_phone = order.contact_phone
        
          # 验证联系电话是否是张三或王芳的电话
          valid_phones = @valid_contact_phones.values
          expect(valid_phones).to include(actual_contact_phone),
            "订单ID: #{order.id}, 联系电话错误。期望其中之一: #{valid_phones.join('或')}, 实际: #{actual_contact_phone}"
        end
      end
    
      # 断言7: 游客名字正确（张三、王芳、小明）
      add_assertion "游客名字正确（张三、王芳、小明）", weight: 15 do
        # 从所有订单中提取 passenger_ids（JSON格式）
        all_passenger_ids = @all_ticket_orders.flat_map { |o| o.passenger_ids || [] }.compact.uniq
        
        expect(all_passenger_ids).not_to be_empty, "订单中未找到任何游客ID"
        
        # 查询实际的游客信息
        user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        actual_passengers = user.passengers.where(id: all_passenger_ids, data_version: 0).to_a
        actual_names = actual_passengers.map(&:name).sort
        
        # 验证游客名字
        expect(actual_names).to match_array(@expected_passenger_names.sort),
          "游客名字错误。期望: #{@expected_passenger_names.sort.join('、')}, 实际: #{actual_names.join('、')}"
      end
    end

    private

    # 状态保存
    def execution_state_data
      {
        attraction_name: @attraction_name,
        visit_date: @visit_date.to_s,
        adult_count: @adult_count,
        child_count: @child_count,
        attraction_id: @attraction&.id,
        zhangsan_id: @zhangsan&.id,
        wangfang_id: @wangfang&.id,
        xiaoming_id: @xiaoming&.id,
        zhangsan_contact_phone: @zhangsan_contact&.phone,
        wangfang_contact_phone: @wangfang_contact&.phone,
        valid_contact_names: @valid_contact_names,
        expected_passenger_names: @expected_passenger_names
      }
    end

    # 状态恢复
    def restore_from_state(data)
      @attraction_name = data['attraction_name']
      @visit_date = Date.parse(data['visit_date'])
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @valid_contact_names = data['valid_contact_names']
      @expected_passenger_names = data['expected_passenger_names']
      
      @attraction = Attraction.find_by(id: data['attraction_id'], data_version: 0) if data['attraction_id']
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by(id: data['zhangsan_id'], data_version: 0) if data['zhangsan_id']
      @wangfang = user.passengers.find_by(id: data['wangfang_id'], data_version: 0) if data['wangfang_id']
      @xiaoming = user.passengers.find_by(id: data['xiaoming_id'], data_version: 0) if data['xiaoming_id']
      @zhangsan_contact = user.contacts.find_by!(name: '张三', data_version: 0)
      @wangfang_contact = user.contacts.find_by!(name: '王芳', data_version: 0)
      
      @valid_contact_phones = {
        '张三' => data['zhangsan_contact_phone'] || @zhangsan_contact.phone,
        '王芳' => data['wangfang_contact_phone'] || @wangfang_contact.phone
      }
    end

    # 模拟AI Agent操作
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      attraction = Attraction.find_by!(name: @attraction_name, data_version: 0)
      
      # 查询成人票和儿童票
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
      
      # 找最便宜的成人票供应商
      cheapest_adult_supplier = nil
      min_adult_price = Float::INFINITY
      
      adult_tickets.each do |ticket|
        ticket.ticket_suppliers.where(data_version: 0).each do |ts|
          if ts.current_price < min_adult_price
            min_adult_price = ts.current_price
            cheapest_adult_supplier = ts
          end
        end
      end
      
      raise "未找到成人票供应商" unless cheapest_adult_supplier
      
      # 找最便宜的儿童票供应商
      cheapest_child_supplier = nil
      min_child_price = Float::INFINITY
      
      child_tickets.each do |ticket|
        ticket.ticket_suppliers.where(data_version: 0).each do |ts|
          if ts.current_price < min_child_price
            min_child_price = ts.current_price
            cheapest_child_supplier = ts
          end
        end
      end
      
      raise "未找到儿童票供应商" unless cheapest_child_supplier
      
      # 查询乘客信息
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 创建成人票订单（2张，游客：张三、王芳）
      adult_order = TicketOrder.create!(
        ticket_id: cheapest_adult_supplier.ticket_id,
        supplier_id: cheapest_adult_supplier.supplier_id,
        user_id: user.id,
        contact_phone: zhangsan.phone,
        passenger_ids: [zhangsan.id, wangfang.id],
        visit_date: @visit_date,
        quantity: @adult_count,
        total_price: cheapest_adult_supplier.current_price * @adult_count,
        status: 'pending',
        notes: '成人票订单（张三、王芳）',
        data_version: @data_version
      )
      
      # 创建儿童票订单（1张，游客：小明）
      child_order = TicketOrder.create!(
        ticket_id: cheapest_child_supplier.ticket_id,
        supplier_id: cheapest_child_supplier.supplier_id,
        user_id: user.id,
        contact_phone: zhangsan.phone,
        passenger_ids: [xiaoming.id],
        visit_date: @visit_date,
        quantity: @child_count,
        total_price: cheapest_child_supplier.current_price * @child_count,
        status: 'pending',
        notes: '儿童票订单（小明）',
        data_version: @data_version
      )
      
      {
        status: 'success',
        message: "已创建2个订单：成人票订单（#{adult_order.id}）和儿童票订单（#{child_order.id}）",
        adult_order_id: adult_order.id,
        child_order_id: child_order.id
      }
    end
  end
end
