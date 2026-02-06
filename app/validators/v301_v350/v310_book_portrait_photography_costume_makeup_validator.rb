# frozen_string_literal: true

require_relative '../base_validator'

# V310: 预订跟拍人像+服装租赁+化妆造型
#
# 任务描述:
#   用户需要预订专业摄影服务套餐，包含跟拍、服装租赁和化妆造型
#
# 评分标准:
#   - 创建了摄影服务订单（活动订单）(40%)
#   - 创建了服装租赁订单（额外活动）(30%)
#   - 服务日期正确 (20%)
#   - 订单状态和价格有效 (10%)
module V301V350
  class V310BookPortraitPhotographyCostumeMakeupValidator < BaseValidator
    self.validator_id = 'v310_book_portrait_photography_costume_makeup_validator'
    self.task_id = '7230b4f9-7181-49ba-9478-979b313bdbca'
    self.title = '预订跟拍人像+服装租赁+化妆造型'
    self.description = '用户需要预订专业摄影服务套餐，包含跟拍、服装租赁和化妆造型'
    self.timeout_seconds = 300
    
    def prepare
      @service_date = Date.current + 7.days
      @participant_count = 1
      
      # 查找适合摄影的景点
      @attraction = Attraction
        .where(data_version: 0)
        .order(Arel.sql('RANDOM()'))
        .first
      
      raise "未找到可用景点" unless @attraction
      
      # 查找摄影相关活动
      @photography_activity = @attraction.attraction_activities.where(data_version: 0).first
      @costume_activity = @attraction.attraction_activities.where(data_version: 0).second
      
      {
        task: "请预订#{@attraction.name}的专业摄影服务（#{@service_date.strftime('%Y年%m月%d日')}，1人），包含人像跟拍、服装租赁和化妆造型。",
        requirements: {
          attraction: @attraction.name,
          service_date: @service_date,
          participant_count: @participant_count,
          services: ['人像跟拍', '服装租赁', '化妆造型']
        },
        hint: "需要预订多个活动服务：摄影跟拍和服装化妆。"
      }
    end
    
    def verify
      add_assertion "创建了摄影服务订单（活动订单）", weight: 40 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @photography_order = all_activity_orders.first
        expect(@photography_order).not_to be_nil, "未找到摄影服务订单"
      end
      
      return if @photography_order.nil?
      
      add_assertion "创建了服装租赁订单（额外活动）", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders.size).to be >= 2,
          "活动订单数量不足。期望至少2个订单（摄影+服装），实际找到#{all_activity_orders.size}个"
        
        @costume_order = all_activity_orders[1]
        expect(@costume_order).not_to be_nil, "未找到服装租赁订单"
      end
      
      add_assertion "服务日期正确", weight: 20 do
        expect(@photography_order.visit_date).to eq(@service_date),
          "摄影服务日期错误。期望: #{@service_date}，实际: #{@photography_order.visit_date}"
        
        if @costume_order
          expect(@costume_order.visit_date).to eq(@service_date),
            "服装租赁日期错误。期望: #{@service_date}，实际: #{@costume_order.visit_date}"
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 10 do
        expect(@photography_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@photography_order.total_price).to be > 0
        
        if @costume_order
          expect(@costume_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@costume_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建摄影服务订单
      photography_activity = @photography_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '专业人像跟拍',
        description: '资深摄影师全程跟拍，提供精修照片50张',
        current_price: 680,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: photography_activity,
        visit_date: @service_date,
        quantity: @participant_count,
        total_price: photography_activity.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建服装租赁+化妆造型订单
      costume_activity = @costume_activity || AttractionActivity.create!(
        attraction: @attraction,
        name: '服装租赁+化妆造型',
        description: '提供多套服装选择，专业化妆师造型设计',
        current_price: 380,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: costume_activity,
        visit_date: @service_date,
        quantity: @participant_count,
        total_price: costume_activity.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        service_date: @service_date.to_s,
        participant_count: @participant_count,
        attraction_id: @attraction&.id,
        photography_activity_id: @photography_activity&.id,
        costume_activity_id: @costume_activity&.id
      }
    end
    
    def restore_from_state(data)
      @service_date = Date.parse(data['service_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @photography_activity = AttractionActivity.find(data['photography_activity_id']) if data['photography_activity_id']
      @costume_activity = AttractionActivity.find(data['costume_activity_id']) if data['costume_activity_id']
    end
  end
end
