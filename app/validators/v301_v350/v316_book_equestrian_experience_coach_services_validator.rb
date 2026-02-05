# frozen_string_literal: true

require_relative '../base_validator'

# V316: 预订马术体验+教练指导+马场服务
#
# 任务描述:
#   用户需要预订马术体验服务，包含专业教练指导和马场服务
#
# 评分标准:
#   - 创建了马术活动订单 (40%)
#   - 活动包含保险（安全保障）(30%)
#   - 活动日期正确 (20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V316BookEquestrianExperienceCoachServicesValidator < BaseValidator
    self.validator_id = 'v316_book_equestrian_experience_coach_services_validator'
    self.task_id = 'f316a001-0001-4001-8001-000000000316'
    self.title = '预订马术体验+教练指导+马场服务'
    self.description = '用户需要预订马术体验服务，包含专业教练指导和马场服务'
    self.timeout_seconds = 300
    
    def prepare
      @activity_date = Date.current + 7.days
      @participant_count = 2
      
      # 查找草原或郊区景点（马场）
      @attraction = Attraction
        .where("name LIKE ? OR name LIKE ?", '%草原%', '%马场%')
        .where(data_version: 0)
        .first
      
      @attraction ||= Attraction.where(data_version: 0).first
      raise "未找到马场景点" unless @attraction
      
      # 查找马术相关活动
      @equestrian_activity = @attraction.attraction_activities.where(data_version: 0).first
      
      {
        task: "请预订#{@attraction.name}的马术体验服务（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含专业教练指导和马场服务。",
        requirements: {
          attraction: @attraction.name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['马术体验', '教练指导', '马场服务', '安全保障']
        },
        hint: "需要预订马术活动，并购买保险确保安全。"
      }
    end
    
    def verify
      add_assertion "创建了马术活动订单", weight: 40 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @equestrian_order = all_activity_orders.first
        expect(@equestrian_order).not_to be_nil, "未找到马术活动订单"
      end
      
      return if @equestrian_order.nil?
      
      add_assertion "活动包含保险（安全保障）", weight: 30 do
        insurance_type = @equestrian_order.insurance_type
        expect(insurance_type).not_to eq('none'),
          "马术活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
      end
      
      add_assertion "活动日期正确", weight: 20 do
        expect(@equestrian_order.visit_date).to eq(@activity_date),
          "马术活动日期错误。期望: #{@activity_date}，实际: #{@equestrian_order.visit_date}"
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@equestrian_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@equestrian_order.total_price).to be > 0
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建马术活动订单（包含教练和马场服务）
      equestrian_activity = @equestrian_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '马术体验（含教练+装备）',
        description: '专业马术教练一对一指导，提供全套骑行装备和护具',
        current_price: 280,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: equestrian_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        total_price: equestrian_activity.current_price * @participant_count,
        insurance_type: 'premium',  # 骑马活动建议购买保险
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        activity_date: @activity_date.to_s,
        participant_count: @participant_count,
        attraction_id: @attraction&.id,
        equestrian_activity_id: @equestrian_activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @equestrian_activity = AttractionActivity.find(data['equestrian_activity_id']) if data['equestrian_activity_id']
    end
  end
end
