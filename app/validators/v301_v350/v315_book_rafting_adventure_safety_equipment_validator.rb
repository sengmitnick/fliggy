# frozen_string_literal: true

require_relative '../base_validator'

# V315: 预订漂流探险+安全保障+装备提供
#
# 任务描述:
#   用户需要预订漂流探险服务，包含安全保障和装备提供
#
# 评分标准:
#   - 创建了漂流活动订单 (40%)
#   - 活动包含保险（安全保障）(30%)
#   - 活动日期正确 (20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V315BookRaftingAdventureSafetyEquipmentValidator < BaseValidator
    self.validator_id = 'v315_book_rafting_adventure_safety_equipment_validator'
    self.task_id = 'aa4e64f9-e897-40dd-9c3e-c0c7fbcf8a58'
    self.title = '预订漂流探险+安全保障+装备提供'
    self.description = '用户需要预订漂流探险服务，包含安全保障和装备提供'
    self.timeout_seconds = 300
    
    def prepare
      @activity_date = Date.current + 5.days
      @participant_count = 4
      
      # 查找水上或山区景点（漂流场所）
      @attraction = Attraction
        .where("name LIKE ? OR name LIKE ? OR name LIKE ?", '%江%', '%河%', '%峡%')
        .where(data_version: 0)
        .first
      
      @attraction ||= Attraction.where(data_version: 0).first
      raise "未找到漂流景点" unless @attraction
      
      # 查找漂流相关活动
      @rafting_activity = @attraction.attraction_activities.where(data_version: 0).first
      
      {
        task: "请预订#{@attraction.name}的漂流探险服务（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含安全保障和全套装备。",
        requirements: {
          attraction: @attraction.name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['漂流探险', '安全保障', '装备提供', '保险']
        },
        hint: "需要预订漂流活动，并购买保险确保安全。"
      }
    end
    
    def verify
      add_assertion "创建了漂流活动订单", weight: 40 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @rafting_order = all_activity_orders.first
        expect(@rafting_order).not_to be_nil, "未找到漂流活动订单"
      end
      
      return if @rafting_order.nil?
      
      add_assertion "活动包含保险（安全保障）", weight: 30 do
        insurance_type = @rafting_order.insurance_type
        expect(insurance_type).not_to eq('none'),
          "漂流活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
      end
      
      add_assertion "活动日期正确", weight: 20 do
        expect(@rafting_order.visit_date).to eq(@activity_date),
          "漂流活动日期错误。期望: #{@activity_date}，实际: #{@rafting_order.visit_date}"
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@rafting_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@rafting_order.total_price).to be > 0
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建漂流活动订单（包含安全保障和装备）
      rafting_activity = @rafting_activity
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: rafting_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        total_price: rafting_activity.current_price * @participant_count,
        insurance_type: 'premium',  # 水上活动建议购买高级保险
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
        rafting_activity_id: @rafting_activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @rafting_activity = AttractionActivity.find(data['rafting_activity_id']) if data['rafting_activity_id']
    end
  end
end
