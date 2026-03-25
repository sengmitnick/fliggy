# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例311: 预订西安华山登山服务套餐（刘强、陈静，6天后，2人，门票+向导装备）
#
# 任务描述:
#   刘强和陈静预订华山登山服务套餐。
#   景点位置：华山（西安）
#   要求：6天后，2人，包含景点门票、登山向导+装备租赁活动。
#   Agent 需要创建两个订单：
#   1) 景点门票订单（TicketOrder）- 华山成人票
#   2) 景点活动订单（ActivityOrder）- 登山向导+装备租赁
#   联系人使用刘强或陈静的信息。
#
# 业务流程（6个关键步骤）：
#   1. 搜索华山景点
#   2. 查找成人门票产品
#   3. 查找登山向导+装备租赁活动
#   4. 确定游玩日期（6天后）和人数（2人）
#   5. 创建两个订单（门票、活动）
#   6. 确保所有订单使用相同的联系人、日期和人数
#
# 复杂度分析（5个关键点）：
#   1. 需要理解登山服务套餐的组合：门票+活动
#   2. 需要创建两种不同类型的订单（TicketOrder + ActivityOrder）
#   3. 需要计算正确的游玩日期（6天后）
#   4. 需要选择demo用户的乘客（刘强或陈静）作为联系人
#   5. 需要确保两个订单的日期、人数、联系人一致
#
# 评分标准（12项，总计100分）：
#   - 创建了景点门票订单（华山登山门票） (18%)
#   - 景点正确（华山） (12%)
#   - 门票类型正确（成人票） (7%)
#   - 门票游玩日期正确（6天后） (7%)
#   - 门票数量正确（2张） (6%)
#   - 门票游客信息正确（刘强+陈静） (8%)
#   - 联系电话正确（刘强或陈静） (7%)
#   - 创建了景点活动订单（登山向导+装备租赁） (15%)
#   - 活动名称正确（包含登山/向导/装备） (7%)
#   - 活动日期正确（6天后） (5%)
#   - 活动人数正确（2人） (5%)
#   - 活动游客信息正确（刘强+陈静） (3%)
module V301V350
  class V311BookMountainGuideEquipmentAccommodationValidator < BaseValidator
    self.validator_id = 'v311_book_mountain_guide_equipment_accommodation_validator'
    self.task_id = 'd31ed871-6c15-42f0-8fd0-3dfbeddca35e'
    self.title = '预订西安华山登山服务套餐（刘强、陈静，6天后，2人，门票+向导装备）'
    self.description = '预订华山登山服务套餐，刘强和陈静，6天后，2人，要景点门票、登山向导+装备租赁。华山位于西安'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for mountain climbing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @travel_date = Date.current + 6.days
      @participant_count = 2
      
      # 固定地点为华山
      @attraction = Attraction
        .joins(:tickets, :attraction_activities)
        .where(name: '华山', data_version: 0)
        .where(tickets: { ticket_type: 'adult', data_version: 0 })
        .where(attraction_activities: { data_version: 0 })
        .first
      
      raise "未找到华山景点" unless @attraction
      
      # 查找华山景点门票（成人票）
      @ticket = @attraction.tickets.where(ticket_type: 'adult', data_version: 0).first
      raise "未找到华山的门票" unless @ticket
      
      # 查找登山活动（向导+装备租赁）
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ? OR name LIKE ? OR name LIKE ?", '%登山%', '%向导%', '%装备%')
        .where(data_version: 0)
        .first
      
      raise "未找到华山的登山活动" unless @climbing_activity
      
      {
        task: "请预订华山登山服务（#{@travel_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含景点门票、登山向导+装备租赁活动。华山位于西安。",
        requirements: {
          attraction: '华山',
          travel_date: @travel_date,
          participant_count: @participant_count,
          ticket: @ticket.name,
          climbing_activity: @climbing_activity.name
        },
        hint: "需要预订华山景点门票和景点活动（登山向导+装备租赁）。"
      }
    end
    
    def verify
      # 断言1: 创建了景点门票订单 (18%)
      add_assertion "创建了景点门票订单（登山门票）", weight: 18 do
        @ticket_order = TicketOrder
          .joins(ticket: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@ticket_order).not_to be_nil, "未找到景点门票订单"
      end
      
      return if @ticket_order.nil?
      
      # 断言2: 景点正确（华山） (12%)
      add_assertion "景点正确（华山）", weight: 12 do
        expect(@ticket_order.ticket.attraction.name).to eq('华山'),
          "景点错误。期望: 华山, 实际: #{@ticket_order.ticket.attraction.name}"
      end
      
      # 断言3: 门票类型正确（成人票） (7%)
      add_assertion "门票类型正确（成人票）", weight: 7 do
        expect(@ticket_order.ticket.ticket_type).to eq('adult'),
          "门票类型错误。期望: adult（成人票）, 实际: #{@ticket_order.ticket.ticket_type}"
      end
      
      # 断言4: 门票游玩日期正确（6天后） (7%)
      add_assertion "门票游玩日期正确（#{@travel_date.strftime('%Y-%m-%d')}）", weight: 7 do
        expect(@ticket_order.visit_date).to eq(@travel_date),
          "门票游玩日期错误。期望: #{@travel_date}（6天后）, 实际: #{@ticket_order.visit_date}"
      end
      
      # 断言5: 门票数量正确（2张） (6%)
      add_assertion "门票数量正确（#{@participant_count}张）", weight: 6 do
        expect(@ticket_order.quantity).to eq(@participant_count),
          "门票数量错误。期望: #{@participant_count}张, 实际: #{@ticket_order.quantity}张"
      end
      
      # 断言6: 门票游客信息正确（刘强+陈静） (8%)
      add_assertion "门票游客信息正确（刘强+陈静）", weight: 8 do
        passengers = @ticket_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "门票游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map { |p| p.respond_to?(:name) ? p.name : p }.compact.sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "门票游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言7: 联系电话正确（刘强或陈静） (7%)
      add_assertion "联系电话正确（刘强或陈静）", weight: 7 do
        expected_phones = [@liuqiang.phone, @chenjing.phone]
        expect(expected_phones).to include(@ticket_order.contact_phone),
          "联系电话错误。期望: #{expected_phones.join('或')}, 实际: #{@ticket_order.contact_phone}"
      end
      
      # 断言8: 创建了景点活动订单（登山向导+装备租赁） (15%)
      add_assertion "创建了景点活动订单（登山向导+装备租赁）", weight: 15 do
        @activity_order = ActivityOrder
          .joins(attraction_activity: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@activity_order).not_to be_nil, "未找到景点活动订单（登山向导+装备）"
      end
      
      return if @activity_order.nil?
      
      # 断言9: 活动名称正确（包含登山/向导/装备） (7%)
      add_assertion "活动名称正确（包含登山/向导/装备）", weight: 7 do
        activity_name = @activity_order.attraction_activity.name
        expect(activity_name).to match(/登山|向导|装备/),
          "活动名称不符合。期望包含: 登山/向导/装备, 实际: #{activity_name}"
      end
      
      # 断言10: 活动日期正确（6天后） (5%)
      add_assertion "活动日期正确（#{@travel_date.strftime('%Y-%m-%d')}）", weight: 5 do
        expect(@activity_order.visit_date).to eq(@travel_date),
          "活动游玩日期错误。期望: #{@travel_date}（6天后）, 实际: #{@activity_order.visit_date}"
      end
      
      # 断言11: 活动人数正确（2人） (5%)
      add_assertion "活动人数正确（#{@participant_count}人）", weight: 5 do
        expect(@activity_order.quantity).to eq(@participant_count),
          "活动人数错误。期望: #{@participant_count}人, 实际: #{@activity_order.quantity}人"
      end
      
      # 断言12: 活动游客信息正确（刘强+陈静） (3%)
      add_assertion "活动游客信息正确（刘强+陈静）", weight: 3 do
        passengers = @activity_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "活动游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map { |p| p.respond_to?(:name) ? p.name : p }.compact.sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "活动游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      

    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the couple as contact
      contact_person = [@liuqiang, @chenjing].sample
      
      # 1. 创建景点门票订单（登山门票）
      TicketOrder.create!(
        user: user,
        ticket: @ticket,
        visit_date: @travel_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],
        contact_phone: contact_person.phone,
        total_price: @ticket.current_price * @participant_count,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建景点活动订单（登山向导+装备租赁）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @climbing_activity,
        visit_date: @travel_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联游客信息
        total_price: @climbing_activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        attraction_id: @attraction&.id,
        ticket_id: @ticket&.id,
        climbing_activity_id: @climbing_activity&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      
      # Restore passenger objects for use in verify assertions
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
    end
  end
end