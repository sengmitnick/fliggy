# frozen_string_literal: true

require_relative '../base_validator'

# V259: 预订高风险活动+专项保险（滑雪/潜水）
#
# 任务描述:
#   用户需要预订滑雪或潜水等高风险活动并购买专项运动保险
#
# 评分标准:
#   - 创建了活动订单 (30%)
#   - 创建了保险订单 (25%)
#   - 保险类型适合高风险运动 (25%)
#   - 保险保障天数正确 (10%)
#   - 订单状态有效 (10%)
module V251V300
  class V259BookHighRiskActivityWithInsuranceValidator < BaseValidator
    self.validator_id = 'v259_book_high_risk_activity_with_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000259'
    self.title = '预订高风险活动+专项保险（滑雪/潜水）'
    self.description = '用户需要预订滑雪或潜水等高风险活动并购买专项运动保险'
    self.timeout_seconds = 300
    
    def prepare
      @activity_type = '滑雪'
      @visit_date = Date.today + 7.days
      
      # 查找滑雪活动
      @activity = AttractionActivity
        .joins(:attraction)
        .where(data_version: 0)
        .where("attraction_activities.name LIKE ? OR attraction_activities.activity_type LIKE ?", "%滑雪%", "%滑雪%")
        .first
      
      # 如果没有找到，使用任意户外活动
      @activity ||= AttractionActivity
        .joins(:attraction)
        .where(data_version: 0)
        .first
      
      raise "未找到#{@activity_type}活动" unless @activity
      
      # 查找适合滑雪的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .select { |p| p.scenes&.include?('滑雪') || p.scenes&.include?('户外运动') }
      
      raise "未找到适合#{@activity_type}的保险产品" if @available_insurances.empty?
      
      {
        task: "请预订#{@activity_type}活动（#{@visit_date.strftime('%Y年%m月%d日')}），并购买专项运动保险（包含高风险运动保障）。",
        requirements: {
          activity_type: @activity_type,
          visit_date: @visit_date,
          insurance_type: '运动保险',
          insurance_coverage: '高风险运动'
        },
        hint: "#{@activity_type}属于高风险运动，需要购买包含运动伤害保障的保险。"
      }
    end
    
    def verify
      add_assertion "创建了活动订单", weight: 30 do
        all_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(data_version: @data_version)
          .to_a
        
        # 查找与活动相关的订单（由于可能使用了备用活动，所以只需要确保订单存在即可）
        @activity_order = all_orders.find do |order|
          # 如果有活动ID，优先匹配
          if @activity&.id
            ticket_name = order.ticket.name
            ticket_name.include?(@activity.name) || ticket_name.include?(@activity_type)
          else
            # 否则只要有订单就行
            true
          end
        end
        
        expect(@activity_order).not_to be_nil, "未找到#{@activity_type}活动订单"
      end
      
      return if @activity_order.nil?
      
      add_assertion "创建了保险订单", weight: 25 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型适合高风险运动", weight: 25 do
        scenes = @insurance_order.insurance_product.scenes || []
        has_sport_coverage = scenes.include?('滑雪') || 
                             scenes.include?('户外运动') ||
                             scenes.include?('潜水')
        
        expect(has_sport_coverage).to be_truthy,
          "保险不包含高风险运动保障。保险场景: #{scenes.inspect}，需要包含'滑雪'或'户外运动'或'潜水'"
      end
      
      add_assertion "保险保障天数正确", weight: 10 do
        insurance_days = @insurance_order.days
        expect(insurance_days).to be >= 1,
          "保险天数不足。保险天数: #{insurance_days}天"
      end
      
      add_assertion "订单状态有效", weight: 10 do
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
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
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
        .select { |p| p.scenes&.include?('滑雪') || p.scenes&.include?('户外运动') }
    end
  end
end
