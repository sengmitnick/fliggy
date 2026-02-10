# frozen_string_literal: true

require_relative '../base_validator'

# V316: 给刘强和陈静预订八达岭国际马场骑马（7天后，2人，必须保险）
#
# 任务描述:
#   刘强和陈静想7天后去八达岭国际马场骑马，需2人，必须购买骑马运动保险以确保安全
#
# 评分标准:
#   - 创建了八达岭国际马场的马术体验订单 (40%)
#   - 马术活动购买了保险（安全保障）(30%)
#   - 活动日期正确（7天后）(20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V316BookEquestrianExperienceCoachServicesValidator < BaseValidator
    self.validator_id = 'v316_book_equestrian_experience_coach_services_validator'
    self.task_id = '244a3782-51c5-4cc3-a3bd-393309099f3b'
    self.title = '给刘强和陈静预订八达岭国际马场骑马（7天后，2人，必须保险）'
    self.description = '刘强和陈静想7天后去八达岭国际马场骑马，需2人，必须购买骑马运动保险以确保安全'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for equestrian)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      @activity_date = Date.current + 7.days
      @participant_count = 2
      
      # 固定景点：八达岭国际马场
      @attraction = Attraction.find_by!(
        name: '八达岭国际马场',
        data_version: 0
      )
      
      # 查找马术体验课程
      @equestrian_activity = @attraction.attraction_activities
        .where("name LIKE ?", '%马术体验%')
        .where(data_version: 0)
        .first!
      
      {
        task: "请预订八达岭国际马场的马术体验课程（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人）。注意：骑马是高风险运动，必须购买保险以确保安全。",
        requirements: {
          attraction: '八达岭国际马场',
          activity_name: '马术体验课程',
          activity_date: @activity_date,
          participant_count: @participant_count,
          insurance_required: true,
          services: ['专业教练指导', '马场服务', '骑马装备租赁', '运动保险']
        },
        hint: "骑马活动存在风险，强烈建议购买保险。"
      }
    end
    
    def verify
      add_assertion "创建了八达岭国际马场的马术体验订单", weight: 40 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到八达岭国际马场的活动订单"
        @equestrian_order = all_activity_orders.first
        expect(@equestrian_order).not_to be_nil, "未找到马术体验订单"
      end
      
      return if @equestrian_order.nil?
      
      add_assertion "马术活动购买了保险（安全保障）", weight: 30 do
        insurance_type = @equestrian_order.insurance_type
        expect(insurance_type).not_to eq('none'),
          "马术活动未购买保险。期望: basic或premium，实际: #{insurance_type}"
      end
      
      add_assertion "活动日期正确（7天后）", weight: 20 do
        expect(@equestrian_order.visit_date).to eq(@activity_date),
          "马术活动日期错误。期望: #{@activity_date}（7天后），实际: #{@equestrian_order.visit_date}"
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@equestrian_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@equestrian_order.total_price).to be > 0
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建马术活动订单（包含教练和马场服务）
      equestrian_activity = @equestrian_activity
      
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
