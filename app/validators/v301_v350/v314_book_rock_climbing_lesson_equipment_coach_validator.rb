# frozen_string_literal: true

require_relative '../base_validator'

# V314: 预订6天后2人华山攀岩教学+安全装备+教练陪同（含保险）
#
# 任务描述:
#   用户需要6天后去华山，2人参加攀岩活动，包含专业教学、安全装备、教练陪同和保险保障
#
# 评分标准:
#   - 创建了攀岩活动订单 (40%)
#   - 活动包含保险（安全保障）(30%)
#   - 活动日期正确 (20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V314BookRockClimbingLessonEquipmentCoachValidator < BaseValidator
    self.validator_id = 'v314_book_rock_climbing_lesson_equipment_coach_validator'
    self.task_id = '58118f22-f2ac-492b-bf85-a73a4786c8aa'
    self.title = '预订6天后2人华山攀岩教学+安全装备+教练陪同（含保险）'
    self.description = '用户需要6天后去华山，2人参加攀岩活动，需创建攀岩活动订单（包含教学、装备、教练），订单必须购买保险（安全保障），活动日期正确，订单状态和价格有效'
    self.timeout_seconds = 300
    
    def prepare
      @activity_date = Date.current + 6.days
      @participant_count = 2
      
      # 固定地点为华山
      @attraction = Attraction
        .where(name: '华山', data_version: 0)
        .first
      
      raise "未找到华山景点" unless @attraction
      
      # 查找华山攀岩活动（攀岩教学+安全装备+教练陪同）
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ?", "%攀岩%")
        .where(data_version: 0)
        .first
      
      raise "未找到华山的攀岩活动" unless @climbing_activity
      
      {
        task: "请预订华山攀岩服务（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含专业教学、安全装备、教练陪同和保险。",
        requirements: {
          attraction: '华山',
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['攀岩教学', '安全装备', '教练陪同', '保险']
        },
        hint: "需要预订华山攀岩活动，并购买保险确保安全。"
      }
    end
    
    def verify
      add_assertion "创建了华山攀岩活动订单", weight: 40 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到华山的活动订单"
        @climbing_order = all_activity_orders.first
        expect(@climbing_order).not_to be_nil, "未找到华山攀岩活动订单"
      end
      
      return if @climbing_order.nil?
      
      add_assertion "活动包含保险（安全保障）", weight: 30 do
        insurance_type = @climbing_order.insurance_type
        expect(insurance_type).not_to eq('none'),
          "攀岩活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
      end
      
      add_assertion "活动日期正确", weight: 20 do
        expect(@climbing_order.visit_date).to eq(@activity_date),
          "攀岩活动日期错误。期望: #{@activity_date}，实际: #{@climbing_order.visit_date}"
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@climbing_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@climbing_order.total_price).to be > 0
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建攀岩活动订单（包含教学、装备、教练）
      climbing_activity = @climbing_activity
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: climbing_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        total_price: climbing_activity.current_price * @participant_count,
        insurance_type: 'premium',  # 高风险活动必须购买保险
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
        climbing_activity_id: @climbing_activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
    end
  end
end
