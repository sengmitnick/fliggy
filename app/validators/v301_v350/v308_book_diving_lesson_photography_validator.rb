# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例308: 预订三亚蜈支洲岛门票+潜水教学+水下摄影（刘强、陈静，4天后，2人）
#
# 任务描述:
#   刘强和陈静预订三亚蜈支洲岛的潜水体验。
#   要求：4天后，2人，包含景区门票、潜水教学+体验、水下摄影服务。
#   Agent 需要创建三个订单：
#   1) 景区门票订单（TicketOrder）
#   2) 潜水教学+体验活动订单（ActivityOrder）
#   3) 水下摄影服务订单（ActivityOrder）
#   联系人使用刘强或陈静的信息。
#
# 业务流程（7个关键步骤）：
#   1. 搜索三亚蜈支洲岛景点
#   2. 查找成人门票产品
#   3. 查找潜水教学+体验活动
#   4. 查找水下摄影服务活动
#   5. 确定游玩日期（4天后）和人数（2人）
#   6. 创建三个订单（门票、潜水、摄影）
#   7. 确保所有订单使用相同的联系人、日期和人数
#
# 复杂度分析（6个关键点）：
#   1. 需要理解潜水体验的服务组合：门票+教学+摄影
#   2. 需要创建三种不同类型的订单（1个TicketOrder + 2个ActivityOrder）
#   3. 需要计算正确的游玩日期（4天后）
#   4. 需要选择demo用户的乘客（刘强或陈静）作为联系人
#   5. 需要确保三个订单的日期、人数、联系人一致
#   6. 需要验证每个订单的状态和价格有效性
#
# 评分标准（7项，总计100分）：
#   - 购买了景区门票 (20%)
#   - 景点正确（蜈支洲岛） (10%)
#   - 预订了潜水活动（潜水教学+体验） (25%)
#   - 预订了摄影服务（水下摄影服务） (20%)
#   - 三个订单的日期均正确（4天后） (10%)
#   - 联系电话正确（刘强或陈静） (10%)
#   - 订单状态和价格有效 (5%)
module V301V350
  class V308BookDivingLessonPhotographyValidator < BaseValidator
    self.validator_id = 'v308_book_diving_lesson_photography_validator'
    self.task_id = '9a83baa7-a2f8-4e7d-bb5c-86a23bf7507a'
    self.title = '预订三亚蜈支洲岛门票+潜水教学+水下摄影（刘强、陈静，4天后，2人）'
    self.description = '预订三亚蜈支洲岛的潜水体验，刘强和陈静，4天后，2人，要景区门票、潜水教学+体验和水下摄影服务'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for diving)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (one of the couple can be contact)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @visit_date = Date.current + 4.days
      @participant_count = 2
      
      @city = '三亚'
      @attraction_name = '蜈支洲岛'
      
      # 查找蜈支洲岛景点（著名潜水胜地）
      @attraction = Attraction.find_by!(name: @attraction_name, city: @city, data_version: 0)
      
      # 查找门票和潜水相关活动
      @adult_ticket = @attraction.tickets.find_by(ticket_type: 'adult', data_version: 0)
      raise "未找到#{@attraction_name}的成人门票" unless @adult_ticket
      
      @diving_activity = @attraction.attraction_activities.find_by(name: '潜水教学+体验', data_version: 0)
      raise "未找到#{@attraction_name}的潜水教学+体验活动" unless @diving_activity
      
      @photography_activity = @attraction.attraction_activities.find_by(name: '水下摄影服务', data_version: 0)
      raise "未找到#{@attraction_name}的水下摄影服务" unless @photography_activity
      
      {
        task: "请预订#{@city}#{@attraction_name}的潜水体验（4天后的#{@visit_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含景区门票、潜水教学+体验和水下摄影服务。",
        requirements: {
          attraction: @attraction_name,
          city: @city,
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['景区门票', '潜水教学+体验', '水下摄影服务']
        },
        hint: "需要购买景区门票，并预订潜水体验和水下摄影服务。"
      }
    end
    
    def verify
      # 断言1: 购买了景区门票
      add_assertion "购买了景区门票", weight: 20 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到门票订单"
        @ticket_order = all_ticket_orders.first
        expect(@ticket_order).not_to be_nil, "未购买景区门票"
        expect(@ticket_order.quantity).to eq(@participant_count),
          "门票数量错误。期望: #{@participant_count}张，实际: #{@ticket_order.quantity}张"
      end
      
      return if @ticket_order.nil?
      
      add_assertion "景点正确（#{@attraction_name}）", weight: 10 do
        expect(@ticket_order.ticket.attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}，实际: #{@ticket_order.ticket.attraction.name}"
      end
      
      # 断言2: 预订了潜水活动
      add_assertion "预订了潜水活动（潜水教学+体验）", weight: 25 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction_name}的活动订单"
        @diving_order = all_activity_orders.find { |o| o.attraction_activity.name.include?('潜水') }
        expect(@diving_order).not_to be_nil, "未预订潜水活动"
      end
      
      return if @diving_order.nil?
      
      # 断言3: 预订了水下摄影服务
      add_assertion "预订了摄影服务（水下摄影服务）", weight: 20 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders.size).to be >= 2,
          "活动订单数量不足。期望至少2个活动（潜水+摄影），实际找到#{all_activity_orders.size}个"
        
        @photography_order = all_activity_orders.find { |o| o.attraction_activity.name.include?('摄影') }
        expect(@photography_order).not_to be_nil, "未预订摄影服务"
      end
      
      # 断言4: 三个订单的日期均正确（4天后）
      add_assertion "三个订单的日期均正确（4天后）", weight: 10 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "门票游玩日期错误。期望: #{@visit_date}（4天后），实际: #{@ticket_order.visit_date}"
        
        expect(@diving_order.visit_date).to eq(@visit_date),
          "潜水活动日期错误。期望: #{@visit_date}（4天后），实际: #{@diving_order.visit_date}"
        
        if @photography_order
          expect(@photography_order.visit_date).to eq(@visit_date),
            "摄影服务日期错误。期望: #{@visit_date}（4天后），实际: #{@photography_order.visit_date}"
        end
      end
      
      add_assertion "联系电话正确（刘强或陈静）", weight: 10 do
        expected_phones = @expected_contact_phones.values
        expect(expected_phones).to include(@ticket_order.contact_phone),
          "联系电话错误。期望: #{expected_phones.join('或')}, 实际: #{@ticket_order.contact_phone}"
      end
      
      # 断言5: 订单状态和价格有效
      add_assertion "订单状态和价格有效", weight: 5 do
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'confirmed']),
          "门票订单状态无效: #{@ticket_order.status}"
        expect(@ticket_order.total_price).to be > 0,
          "门票订单总价无效: #{@ticket_order.total_price}"
        
        expect(@diving_order.status).to be_in(['pending', 'paid', 'confirmed']),
          "潜水订单状态无效: #{@diving_order.status}"
        expect(@diving_order.total_price).to be > 0,
          "潜水订单总价无效: #{@diving_order.total_price}"
        
        if @photography_order
          expect(@photography_order.status).to be_in(['pending', 'paid', 'confirmed']),
            "摄影订单状态无效: #{@photography_order.status}"
          expect(@photography_order.total_price).to be > 0,
            "摄影订单总价无效: #{@photography_order.total_price}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 随机选择一位作为联系人
      contact_person = [@liuqiang, @chenjing].sample
      
      # 1. 创建门票订单（TicketOrder）
      TicketOrder.create!(
        user: user,
        ticket: @adult_ticket,
        visit_date: @visit_date,
        quantity: @participant_count,
        contact_phone: contact_person.phone,
        total_price: @adult_ticket.current_price * @participant_count,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建潜水活动订单（ActivityOrder）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @diving_activity,
        visit_date: @visit_date,
        quantity: @participant_count,
        passenger_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @diving_activity.current_price * @participant_count,
        insurance_type: 'premium',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建摄影服务订单（ActivityOrder）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @photography_activity,
        visit_date: @visit_date,
        quantity: @participant_count,
        passenger_name: contact_person.name,
        contact_phone: contact_person.phone,
        total_price: @photography_activity.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        visit_date: @visit_date.to_s,
        participant_count: @participant_count,
        city: @city,
        attraction_name: @attraction_name,
        attraction_id: @attraction&.id,
        adult_ticket_id: @adult_ticket&.id,
        diving_activity_id: @diving_activity&.id,
        photography_activity_id: @photography_activity&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      @city = data['city']
      @attraction_name = data['attraction_name']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @adult_ticket = Ticket.find(data['adult_ticket_id']) if data['adult_ticket_id']
      @diving_activity = AttractionActivity.find(data['diving_activity_id']) if data['diving_activity_id']
      @photography_activity = AttractionActivity.find(data['photography_activity_id']) if data['photography_activity_id']
    end
  end
end