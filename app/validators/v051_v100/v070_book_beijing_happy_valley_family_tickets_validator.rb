# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例70: 张三一家预订明天北京欢乐谷门票（2成人+1儿童）
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
#   - 联系人和联系电话正确 (25分)
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
    self.title = '张三一家预订明天北京欢乐谷门票（2成人+1儿童）'
    self.description = '张三一家预订明天北京欢乐谷门票（2成人+1儿童）'
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
    
      # 断言6: 联系人和联系电话正确
      add_assertion "联系人和联系电话正确（可以是张三或王芳）", weight: 25 do
        @all_ticket_orders.each do |order|
          actual_contact_name = order.contact_name
          actual_contact_phone = order.contact_phone
        
          expect(@valid_contact_names).to include(actual_contact_name),
            "订单ID: #{order.id}, 联系人错误。期望其中之一: #{@valid_contact_names.join('或')}, 实际: #{actual_contact_name}"
        
          expected_phone = @valid_contact_phones[actual_contact_name]
          expect(actual_contact_phone).to eq(expected_phone),
            "订单ID: #{order.id}, 联系人#{actual_contact_name}的电话错误。期望: #{expected_phone}, 实际: #{actual_contact_phone}"
        end
      end
    end
  end
end
