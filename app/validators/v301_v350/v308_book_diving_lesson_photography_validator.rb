# frozen_string_literal: true

require_relative '../base_validator'

# V308: 预订潜水教学+潜水体验+水下摄影
#
# 任务描述:
#   用户需要预订潜水服务套餐，包含教学、体验和水下摄影服务
#
# 评分标准:
#   - 创建了潜水活动订单 (35%)
#   - 创建了摄影服务订单（额外活动）(30%)
#   - 活动日期正确 (20%)
#   - 订单状态和价格有效 (15%)
module V301V350
  class V308BookDivingLessonPhotographyValidator < BaseValidator
    self.validator_id = 'v308_book_diving_lesson_photography_validator'
    self.task_id = 'f308a001-0001-4001-8001-000000000308'
    self.title = '预订潜水教学+潜水体验+水下摄影'
    self.description = '用户需要预订潜水服务套餐，包含教学、体验和水下摄影服务'
    self.timeout_seconds = 300
    
    def prepare
      @visit_date = Date.today + 4.days
      @participant_count = 2
      
      # 查找海岛或海滨景点（支持潜水活动）
      @attraction = Attraction
        .where("name LIKE ? OR name LIKE ? OR name LIKE ?", '%海%', '%岛%', '%滨%')
        .where(data_version: 0)
        .first
      
      @attraction ||= Attraction.where(data_version: 0).first
      raise "未找到海岛景点" unless @attraction
      
      # 查找潜水相关活动
      @diving_activity = @attraction.attraction_activities.where(data_version: 0).first
      @photography_activity = @attraction.attraction_activities.where(data_version: 0).second
      
      {
        task: "请预订#{@attraction.name}的潜水服务（#{@visit_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含潜水教学、潜水体验和水下摄影。",
        requirements: {
          attraction: @attraction.name,
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['潜水教学', '潜水体验', '水下摄影']
        },
        hint: "需要预订2个活动：潜水体验和摄影服务。"
      }
    end
    
    def verify
      add_assertion "创建了潜水活动订单", weight: 35 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @diving_order = all_activity_orders.first
        expect(@diving_order).not_to be_nil, "未找到潜水活动订单"
      end
      
      return if @diving_order.nil?
      
      add_assertion "创建了摄影服务订单（额外活动）", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders.size).to be >= 2,
          "活动订单数量不足。期望至少2个订单（潜水+摄影），实际找到#{all_activity_orders.size}个"
        
        @photography_order = all_activity_orders[1]
        expect(@photography_order).not_to be_nil, "未找到摄影服务订单"
      end
      
      add_assertion "活动日期正确", weight: 20 do
        expect(@diving_order.visit_date).to eq(@visit_date),
          "潜水活动日期错误。期望: #{@visit_date}，实际: #{@diving_order.visit_date}"
        
        if @photography_order
          expect(@photography_order.visit_date).to eq(@visit_date),
            "摄影服务日期错误。期望: #{@visit_date}，实际: #{@photography_order.visit_date}"
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 15 do
        expect(@diving_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@diving_order.total_price).to be > 0
        
        if @photography_order
          expect(@photography_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@photography_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建潜水活动订单
      diving_activity = @diving_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '潜水教学+体验',
        description: '专业教练带领，适合初学者',
        current_price: 380,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: diving_activity,
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: diving_activity.current_price * @participant_count,
        insurance_type: 'premium',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建摄影服务订单
      photography_activity = @photography_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '水下摄影服务',
        description: '专业摄影师全程跟拍，提供精修照片',
        current_price: 200,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: photography_activity,
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: photography_activity.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        visit_date: @visit_date.to_s,
        participant_count: @participant_count,
        attraction_id: @attraction&.id,
        diving_activity_id: @diving_activity&.id,
        photography_activity_id: @photography_activity&.id
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @diving_activity = AttractionActivity.find(data['diving_activity_id']) if data['diving_activity_id']
      @photography_activity = AttractionActivity.find(data['photography_activity_id']) if data['photography_activity_id']
    end
  end
end
