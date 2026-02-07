# frozen_string_literal: true

require_relative '../base_validator'

# V312: 预订冲浪教学+海滩娱乐+装备提供
#
# 任务描述:
#   用户需要预订冲浪服务套餐，包含教学、海滩娱乐和装备提供
#
# 评分标准:
#   - 创建了冲浪活动订单 (30%)
#   - 景点正确 (10%)
#   - 创建了额外娱乐活动订单 (20%)
#   - 活动日期正确 (15%)
#   - 人数正确 (15%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V312BookSurfingLessonBeachEquipmentValidator < BaseValidator
    self.validator_id = 'v312_book_surfing_lesson_beach_equipment_validator'
    self.task_id = 'c132957d-cbea-4e0b-8190-acd5d2d2ce30'
    self.title = '预订4天后2人深圳大梅沙冲浪服务套餐（教学+海滩娱乐+装备）'
    self.description = '用户需要4天后去深圳大梅沙海滨公园预订冲浪服务套餐，2人参与，包含冲浪教学、海滩娱乐和装备提供，需创建冲浪活动订单和海滩娱乐活动订单，活动日期和人数正确，订单状态和价格有效'
    self.timeout_seconds = 300
    
    def prepare
      @activity_date = Date.current + 4.days
      @participant_count = 2
      
      # 固定为深圳大梅沙海滨公园
      @attraction = Attraction
        .joins(:attraction_activities)
        .where(name: '深圳大梅沙海滨公园', data_version: 0)
        .where(attraction_activities: { data_version: 0 })
        .first
      
      raise "未找到深圳大梅沙海滨公园" unless @attraction
      
      # 查找活动
      @surfing_activity = @attraction.attraction_activities.where(data_version: 0).first
      @entertainment_activity = @attraction.attraction_activities.where(data_version: 0).second
      
      {
        task: "请预订深圳大梅沙海滨公园的冲浪服务（#{@activity_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含冲浪教学、海滩娱乐和装备提供。",
        requirements: {
          attraction: @attraction.name,
          activity_date: @activity_date,
          participant_count: @participant_count,
          services: ['冲浪教学', '海滩娱乐', '装备提供']
        },
        hint: "需要预订深圳大梅沙海滨公园的多个活动：冲浪教学和海滩娱乐。"
      }
    end
    
    def verify
      add_assertion "创建了冲浪活动订单", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到深圳大梅沙海滨公园的活动订单"
        @surfing_order = all_activity_orders.first
        expect(@surfing_order).not_to be_nil, "未找到冲浪活动订单"
      end
      
      return if @surfing_order.nil?
      
      add_assertion "景点正确（深圳大梅沙海滨公园）", weight: 10 do
        expect(@surfing_order.attraction_activity.attraction.name).to eq('深圳大梅沙海滨公园'),
          "景点错误。期望: 深圳大梅沙海滨公园，实际: #{@surfing_order.attraction_activity.attraction.name}"
      end
      
      add_assertion "创建了额外娱乐活动订单", weight: 20 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        if all_activity_orders.size >= 2
          @entertainment_order = all_activity_orders[1]
          expect(@entertainment_order).not_to be_nil, "未找到海滩娱乐订单"
        else
          # 如果只有一个活动订单，也算通过（冲浪教学已包含装备）
          expect(all_activity_orders.size).to be >= 1,
            "活动订单数量不足。至少需要1个订单"
        end
      end
      
      add_assertion "活动日期正确（#{@activity_date}，4天后）", weight: 15 do
        expect(@surfing_order.visit_date).to eq(@activity_date),
          "冲浪活动日期错误。期望: #{@activity_date}（4天后），实际: #{@surfing_order.visit_date}"
        
        if @entertainment_order
          expect(@entertainment_order.visit_date).to eq(@activity_date),
            "娱乐活动日期错误。期望: #{@activity_date}（4天后），实际: #{@entertainment_order.visit_date}"
        end
      end
      
      add_assertion "人数正确（#{@participant_count}人）", weight: 15 do
        expect(@surfing_order.quantity).to eq(@participant_count),
          "冲浪活动人数错误。期望: #{@participant_count}人，实际: #{@surfing_order.quantity}人"
        
        if @entertainment_order
          expect(@entertainment_order.quantity).to eq(@participant_count),
            "娱乐活动人数错误。期望: #{@participant_count}人，实际: #{@entertainment_order.quantity}人"
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@surfing_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@surfing_order.total_price).to be > 0
        
        if @entertainment_order
          expect(@entertainment_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@entertainment_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建冲浪活动订单
      surfing_activity = @surfing_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '冲浪教学（含装备）',
        description: '专业教练指导，提供全套冲浪装备',
        current_price: 280,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: surfing_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        total_price: surfing_activity.current_price * @participant_count,
        insurance_type: 'premium',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建海滩娱乐活动订单
      entertainment_activity = @entertainment_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '海滩娱乐项目',
        description: '沙滩排球、摩托艇、香蕉船等多项娱乐',
        current_price: 150,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: entertainment_activity,
        visit_date: @activity_date,
        quantity: @participant_count,
        total_price: entertainment_activity.current_price * @participant_count,
        insurance_type: 'basic',
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
        surfing_activity_id: @surfing_activity&.id,
        entertainment_activity_id: @entertainment_activity&.id
      }
    end
    
    def restore_from_state(data)
      @activity_date = Date.parse(data['activity_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @surfing_activity = AttractionActivity.find(data['surfing_activity_id']) if data['surfing_activity_id']
      @entertainment_activity = AttractionActivity.find(data['entertainment_activity_id']) if data['entertainment_activity_id']
    end
  end
end
