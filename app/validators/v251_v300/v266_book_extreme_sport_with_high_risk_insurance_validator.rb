# frozen_string_literal: true

require_relative '../base_validator'

# V266: 预订山景景点5天后攀岩活动+购买含运动伤害保障保险
#
# 任务描述:
#   用户需要在山景景点（名称含"山"或"峰"）预订5天后的攀岩活动，
#   并购买包含运动伤害保障（滑雪/户外运动/潜水场景或运动伤害保额>0）的专项保险，
#   确保订单状态有效
#
# 评分标准:
#   - 创建了攀岩活动订单（山景景点，5天后） (25%)
#   - 活动日期正确（5天后） (10%)
#   - 创建了保险订单 (20%)
#   - 保险包含高风险运动保障（滑雪/户外运动/潜水场景或运动伤害保额>0） (35%)
#   - 订单状态有效（pending/paid/completed） (10%)
module V251V300
  class V266BookExtremeSportWithHighRiskInsuranceValidator < BaseValidator
    self.validator_id = 'v266_book_extreme_sport_with_high_risk_insurance_validator'
    self.task_id = '97bbddca-e45e-43e7-814c-88eaf6396ea0'
    self.title = '预订山景景点5天后攀岩活动+购买含运动伤害保障保险'
    self.description = '用户需要在山景景点（名称含"山"或"峰"）预订5天后的攀岩活动，并购买包含运动伤害保障（滑雪/户外运动/潜水场景或运动伤害保额>0）的专项保险，确保订单状态有效'
    self.timeout_seconds = 300
    
    def prepare
      @activity_type = '攀岩'
      @visit_date = Date.current + 5.days
      
      # 查找适合攀岩的山景景点
      @attraction = Attraction
        .where("name LIKE ? OR name LIKE ?", '%山%', '%峰%')
        .where(data_version: 0)
        .first
      
      # 如果没有山景景点，使用任意景点
      @attraction ||= Attraction.where(data_version: 0).first
      
      raise "未找到适合攀岩的景点" unless @attraction
      
      # 查找攀岩相关活动（如果存在）
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ? OR description LIKE ?", "%#{@activity_type}%", "%极限%")
        .where(data_version: 0)
        .first
      
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
        task: "请在#{@attraction.name}预订攀岩活动（#{@visit_date.strftime('%Y年%m月%d日')}），并购买高风险专项保险（包含运动伤害保障）。",
        requirements: {
          attraction: @attraction.name,
          activity_type: '攀岩',
          visit_date: @visit_date,
          insurance_type: '高风险运动保险',
          insurance_coverage: '运动伤害保障'
        },
        hint: "攀岩属于高风险运动，需要购买包含运动伤害保障的专项保险（如极限运动保险或滑雪运动保险）。"
      }
    end
    
    def verify
      add_assertion "创建了攀岩活动订单（山景景点，5天后）", weight: 25 do
        all_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(attraction_activity: :attraction)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @activity_order = all_orders.first
      end
      
      return if @activity_order.nil?
      
      add_assertion "活动日期正确（5天后）", weight: 10 do
        expect(@activity_order.visit_date).to eq(@visit_date),
          "活动日期错误。期望: #{@visit_date}（5天后），实际: #{@activity_order.visit_date}"
      end
      
      add_assertion "创建了保险订单", weight: 20 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险包含高风险运动保障", weight: 35 do
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
      
      add_assertion "订单状态有效（pending/paid/completed）", weight: 10 do
        expect(@activity_order.status).to be_in(['pending', 'paid', 'confirmed', 'completed']),
          "活动订单状态无效。期望: pending/paid/confirmed/completed，实际: #{@activity_order.status}"
        expect(@insurance_order.status).to be_in(['pending', 'paid']),
          "保险订单状态无效。期望: pending/paid，实际: #{@insurance_order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建攀岩活动订单
      climbing_activity = @climbing_activity
      
      activity_order = ActivityOrder.create!(
        user: user,
        attraction_activity: climbing_activity,
        visit_date: @visit_date,
        quantity: 1,
        total_price: climbing_activity.current_price,
        insurance_type: 'premium',  # 高风险活动建议购买保险
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建保险订单（优先选择有攀岩场景的，其次运动伤害保额>0的）
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
        attraction_id: @attraction&.id,
        climbing_activity_id: @climbing_activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_type = data['activity_type']
      @visit_date = Date.parse(data['visit_date'])
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      
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
