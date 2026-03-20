# frozen_string_literal: true

require_relative '../base_validator'

# V266: 帮张三预订5天后去西安华山的攀岩活动（1人），需要购买华山景区门票、预订攀岩活动（攀岩教学+安全装备+教练陪同）、购买包含运动伤害保障的专项保险，确保三个订单的时间一致，出行人信息一致
#
# 任务描述:
#   帮张三预订5天后去华山（西安）的攀岩活动（1人），需要完成：
#   1. 购买华山景区门票（成人票）
#   2. 预订华山攀岩活动（攀岩教学+安全装备+教练陪同）
#   3. 购买包含运动伤害保障的专项保险（境内旅游险，优先选择含攀岩/户外运动场景）
#   确保三个订单的时间一致（5天后），出行人信息一致（张三）。
#   攀岩属于高风险运动，需要购买包含运动伤害保障的专项保险。
#
# 业务流程:
#   1. 用户输入：目的地（华山，西安）、游玩日期（5天后）、活动类型（攀岩）、人数（1人：张三）、需求（门票+活动+保险）
#   2. 系统筛选：显示华山景区门票、华山攀岩活动（5天后可约），同时展示适配的运动保险（含攀岩/户外运动场景）
#   3. 用户选择：选择华山成人票、攀岩活动（教学+装备+教练）、高风险运动保险
#   4. 填写信息：游玩日期（5天后）、联系人（张三）、被保险人（张三）
#   5. 确认支付：核对门票订单、活动订单、保险订单信息和总价格
#   6. 完成订单：生成3个订单（TicketOrder + ActivityOrder + InsuranceOrder），保险关联到ActivityOrder
#   7. 获取凭证：获取门票凭证、活动预约凭证、保险凭证
#
# 复杂度分析:
#   1. **多订单关联逻辑**（高）：需同时创建TicketOrder、ActivityOrder和InsuranceOrder，并建立关联关系，比通常的双订单更复杂
#   2. **高风险运动保险筛选**（高）：必须识别适合高风险运动的保险（含攀岩/户外运动场景 或 运动伤害保额>0），优先选择攀岩场景
#   3. **三个订单时间一致性验证**（中）：验证门票游玩日期、活动游玩日期、保险起止日期都要匹配同一天（5天后）
#   4. **三个订单出行人一致性验证**（中）：验证门票订单联系人、活动订单联系人、保险订单被保险人都是张三
#   5. **景区门票+活动组合**（低）：验证活动所属景区与门票景区一致（都是华山）
#
# 评分标准（总分100%）:
#   - 创建了华山门票订单 (15%) - 基础操作
#   - 创建了华山攀岩活动订单 (15%) - 基础操作
#   - 创建了保险订单 (15%) - 基础操作
#   - 门票和活动的游玩日期一致（5天后） (15%) - 核心要求（最高权重之一）
#   - 保险时间覆盖活动日期 (10%) - 业务逻辑正确性
#   - 三个订单的出行人信息一致（张三） (15%) - 核心要求（最高权重之一）
#   - 保险包含高风险运动保障 (10%) - 核心要求（攀岩/户外运动场景 或 运动伤害保额>0）
#   - 订单状态有效（pending/paid/completed） (5%) - 订单可用性
module V251V300
  class V266BookExtremeSportWithHighRiskInsuranceValidator < BaseValidator
    self.validator_id = 'v266_book_extreme_sport_with_high_risk_insurance_validator'
    self.task_id = '97bbddca-e45e-43e7-814c-88eaf6396ea0'
    self.title = '帮张三预订5天后去西安华山的攀岩活动（1人），需要购买华山景区门票、预订攀岩活动（攀岩教学+安全装备+教练陪同）、购买包含运动伤害保障的专项保险，确保三个订单的时间一致，出行人信息一致'
    self.description = '帮张三预订5天后去华山的攀岩活动，需要购买华山景区门票、预订攀岩活动（攀岩教学+安全装备+教练陪同）、购买包含运动伤害保障的专项保险，确保三个订单的时间一致，出行人信息一致'
    self.timeout_seconds = 300
    
    def prepare
      @visit_date = Date.current + 5.days
      
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_phone = @zhangsan.phone
      
      # 查找华山景点
      @attraction = Attraction.find_by!(name: '华山', data_version: 0)
      
      # 查找华山门票（成人票）
      @ticket = @attraction.tickets
        .where(ticket_type: 'adult', data_version: 0)
        .first!
      
      # 查找华山攀岩活动
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ?", "%攀岩%")
        .where(data_version: 0)
        .first!
      
      # 查找适合攀岩的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select do |p| 
          scenes = p.scenes || []
          scenes.include?('攀岩') ||  # 优先选择含攀岩场景的产品
          scenes.include?('滑雪') || 
          scenes.include?('户外运动') ||
          (p.coverage_details['sports_injury'] || 0) > 0
        end
      
      # 如果没有专项运动保险，使用普通保险
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'domestic', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', 1, 1)
          .to_a
      end
      
      raise "未找到适合的保险产品" if @available_insurances.empty?
      
      {
        task: "请帮张三预订#{@visit_date.strftime('%Y年%m月%d日')}（5天后）去华山的攀岩活动，需要：1. 购买华山景区门票 2. 预订攀岩活动（攀岩教学+安全装备+教练陪同） 3. 购买包含运动伤害保障的专项保险。",
        requirements: {
          attraction: '华山',
          visit_date: @visit_date,
          ticket: '华山景区成人票',
          activity: '攀岩教学+安全装备+教练陪同',
          insurance_type: '高风险运动保险（含运动伤害保障）',
          traveler: '张三'
        },
        hint: "攀岩属于高风险运动，需要先购买景区门票，再预订攀岩活动，最后购买包含运动伤害保障的专项保险。"
      }
    end
    
    def verify
      add_assertion "创建了华山门票订单", weight: 15 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: '华山' } })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到华山门票订单"
        @ticket_order = all_ticket_orders.first
      end
      
      return if @ticket_order.nil?
      
      add_assertion "创建了华山攀岩活动订单", weight: 15 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(attraction_activity: :attraction)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到华山攀岩活动订单"
        @activity_order = all_activity_orders.first
      end
      
      return if @activity_order.nil?
      
      add_assertion "创建了保险订单", weight: 15 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "门票和活动的游玩日期一致（5天后）", weight: 15 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "门票游玩日期错误。期望: #{@visit_date}（5天后），实际: #{@ticket_order.visit_date}"
        expect(@activity_order.visit_date).to eq(@visit_date),
          "活动游玩日期错误。期望: #{@visit_date}（5天后），实际: #{@activity_order.visit_date}"
      end
      
      add_assertion "保险时间覆盖活动日期", weight: 10 do
        expect(@insurance_order.start_date).to be <= @visit_date,
          "保险开始日期晚于活动日期。保险开始日期: #{@insurance_order.start_date}，活动日期: #{@visit_date}"
        expect(@insurance_order.end_date).to be >= @visit_date,
          "保险结束日期早于活动日期。保险结束日期: #{@insurance_order.end_date}，活动日期: #{@visit_date}"
      end
      
      add_assertion "三个订单的出行人信息一致（张三）", weight: 15 do
        # 门票订单联系人
        expect(@ticket_order.contact_phone).to eq(@expected_contact_phone),
          "门票订单联系电话错误。期望: #{@expected_contact_phone}（张三），实际: #{@ticket_order.contact_phone}"
        
        # 活动订单联系人
        expect(@activity_order.contact_phone).to eq(@expected_contact_phone),
          "活动订单联系电话错误。期望: #{@expected_contact_phone}（张三），实际: #{@activity_order.contact_phone}"
        
        # 保险订单被保险人
        insured_persons = @insurance_order.insured_persons || []
        actual_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact
        expect(actual_names).to include(@zhangsan.name),
          "保险订单被保险人错误。期望包含: #{@zhangsan.name}，实际: #{actual_names.join('、')}"
      end
      
      add_assertion "保险包含高风险运动保障", weight: 10 do
        scenes = @insurance_order.insurance_product.scenes || []
        coverage = @insurance_order.insurance_product.coverage_details || {}
        
        has_sport_coverage = scenes.include?('攀岩') ||  # 最佳选择
                             scenes.include?('滑雪') || 
                             scenes.include?('户外运动') ||
                             scenes.include?('潜水') ||
                             coverage['sports_injury'].to_i > 0
        
        expect(has_sport_coverage).to be_truthy,
          "保险不包含高风险运动保障。保险场景: #{scenes.inspect}，运动伤害保额: #{coverage['sports_injury'] || 0}元"
      end
      
      add_assertion "订单状态有效（pending/paid/completed）", weight: 5 do
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'confirmed', 'completed']),
          "门票订单状态无效。期望: pending/paid/confirmed/completed，实际: #{@ticket_order.status}"
        expect(@activity_order.status).to be_in(['pending', 'paid', 'confirmed', 'completed']),
          "活动订单状态无效。期望: pending/paid/confirmed/completed，实际: #{@activity_order.status}"
        expect(@insurance_order.status).to be_in(['pending', 'paid']),
          "保险订单状态无效。期望: pending/paid，实际: #{@insurance_order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建华山门票订单
      ticket_order = TicketOrder.create!(
        user: user,
        ticket: @ticket,
        visit_date: @visit_date,
        quantity: 1,
        contact_phone: @expected_contact_phone,
        total_price: @ticket.current_price,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建华山攀岩活动订单
      activity_order = ActivityOrder.create!(
        user: user,
        attraction_activity: @climbing_activity,
        visit_date: @visit_date,
        quantity: 1,
        contact_phone: @expected_contact_phone,
        total_price: @climbing_activity.current_price,
        insurance_type: 'premium',  # 高风险活动建议购买保险
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建保险订单（优先选择有攀岩场景的，其次运动伤害保额>0的）
      insurance_product = @available_insurances
        .select { |p| (p.scenes || []).include?('攀岩') }
        .first
      
      insurance_product ||= @available_insurances
        .select { |p| (p.coverage_details['sports_injury'] || 0) > 0 }
        .first || @available_insurances.first
      
      start_date = @visit_date
      end_date = @visit_date
      days = 1
      unit_price = insurance_product.price_per_day * days
      
      insured_persons_data = [{
        name: @zhangsan.name,
        id_number: @zhangsan.id_number
      }]
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'ActivityOrder',
        related_booking_id: activity_order.id,
        start_date: start_date,
        end_date: end_date,
        days: days,
        destination: @attraction.city,
        destination_type: 'domestic',
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        quantity: 1,
        total_price: unit_price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        visit_date: @visit_date.to_s,
        attraction_id: @attraction&.id,
        ticket_id: @ticket&.id,
        climbing_activity_id: @climbing_activity&.id,
        zhangsan_id: @zhangsan&.id
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      
      # 恢复乘客信息
      if data['zhangsan_id']
        @zhangsan = Passenger.find(data['zhangsan_id'])
        @expected_contact_phone = @zhangsan.phone
      end
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select do |p| 
          scenes = p.scenes || []
          scenes.include?('攀岩') ||  # 优先选择含攀岩场景的产品
          scenes.include?('滑雪') || 
          scenes.include?('户外运动') ||
          (p.coverage_details['sports_injury'] || 0) > 0
        end
      
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'domestic', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', 1, 1)
          .to_a
      end
    end
  end
end
