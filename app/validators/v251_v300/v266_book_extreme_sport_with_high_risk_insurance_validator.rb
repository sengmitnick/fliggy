# frozen_string_literal: true

require_relative '../base_validator'

# V266: 预订极限运动+高风险专项保险
#
# 任务描述:
#   用户需要预订极限运动（攀岩/跳伞/蹦极等）并购买高风险专项保险
#
# 评分标准:
#   - 创建了活动订单 (30%)
#   - 创建了保险订单 (30%)
#   - 保险包含高风险运动保障 (25%)
#   - 订单状态有效 (15%)
module V251V300
  class V266BookExtremeSportWithHighRiskInsuranceValidator < BaseValidator
    self.validator_id = 'v266_book_extreme_sport_with_high_risk_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000266'
    self.title = '预订极限运动+高风险专项保险'
    self.description = '用户需要预订极限运动（攀岩/跳伞/蹦极等）并购买高风险专项保险'
    self.timeout_seconds = 300
    
    def prepare
      @activity_type = '攀岩'
      @visit_date = Date.current + 5.days
      
      # 查找极限运动活动
      @activity = AttractionActivity
        .joins(:attraction)
        .where(data_version: 0)
        .where("attraction_activities.name LIKE ? OR attraction_activities.description LIKE ?", 
               "%#{@activity_type}%", "%极限%")
        .first
      
      # 如果没有找到，使用任意户外活动
      @activity ||= AttractionActivity
        .joins(:attraction)
        .where(data_version: 0)
        .first
      
      raise "未找到极限运动活动" unless @activity
      
      # 查找适合极限运动的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select do |p| 
          scenes = p.scenes || []
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
        task: "请预订极限运动活动（#{@activity_type}，#{@visit_date.strftime('%Y年%m月%d日')}），并购买高风险专项保险（包含运动伤害保障）。",
        requirements: {
          activity_type: '极限运动',
          visit_date: @visit_date,
          insurance_type: '高风险运动保险',
          insurance_coverage: '运动伤害'
        },
        hint: "极限运动风险高，需要购买包含运动伤害保障的专项保险。"
      }
    end
    
    def verify
      add_assertion "创建了活动订单", weight: 30 do
        all_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(data_version: @data_version)
          .to_a
        
        @activity_order = all_orders.first
        expect(@activity_order).not_to be_nil, "未找到活动订单"
      end
      
      return if @activity_order.nil?
      
      add_assertion "创建了保险订单", weight: 30 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险包含高风险运动保障", weight: 25 do
        scenes = @insurance_order.insurance_product.scenes || []
        coverage = @insurance_order.insurance_product.coverage_details || {}
        
        has_sport_coverage = scenes.include?('滑雪') || 
                             scenes.include?('户外运动') ||
                             scenes.include?('潜水') ||
                             coverage['sports_injury'].to_i > 0
        
        expect(has_sport_coverage).to be_truthy,
          "保险不包含高风险运动保障。保险场景: #{scenes.inspect}，运动伤害保额: #{coverage['sports_injury'] || 0}元"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@activity_order.status).to be_in(['pending', 'paid', 'completed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建活动订单（使用门票订单模拟）
      attraction = @activity.attraction
      
      # 查找或创建门票
      ticket = Ticket.find_or_create_by!(
        attraction: attraction,
        name: "#{@activity.name}门票",
        data_version: 0
      ) do |t|
        t.ticket_type = 'adult'
        t.current_price = @activity.current_price
        t.original_price = @activity.current_price
      end
      
      activity_order = TicketOrder.create!(
        user: user,
        ticket: ticket,
        visit_date: @visit_date,
        quantity: 1,
        contact_phone: '13800138000',
        total_price: @activity.current_price,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建保险订单（优先选择有运动伤害保障的）
      insurance_product = @available_insurances
        .select { |p| (p.coverage_details['sports_injury'] || 0) > 0 }
        .first || @available_insurances.first
      
      start_date = @visit_date
      end_date = @visit_date
      days = 1
      unit_price = insurance_product.price_per_day * days
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'TicketOrder',
        related_booking_id: activity_order.id,
        start_date: start_date,
        end_date: end_date,
        days: days,
        destination: attraction.city,
        destination_type: 'domestic',
        insured_persons: [user.name],
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
        activity_type: @activity_type,
        visit_date: @visit_date.to_s,
        activity_id: @activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_type = data['activity_type']
      @visit_date = Date.parse(data['visit_date'])
      
      @activity = AttractionActivity.find(data['activity_id']) if data['activity_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select do |p| 
          scenes = p.scenes || []
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
