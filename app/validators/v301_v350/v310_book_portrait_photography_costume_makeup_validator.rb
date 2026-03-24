# frozen_string_literal: true

require_relative '../base_validator'

# V310: 预订门票-上海东方明珠园内项目·人像摄影套餐（给张三预订，7天后，2个服务项目：跟拍+服装化妆）
#
# 任务描述:
#   给1个人预订7天后的摄影服务套餐（单人服务）。
#   
#   服务内容：
#   - 人像跟拍服务（688元/人）
#   - 服装租赁+化妆造型服务（388元/人）
#   
#   预订细节：
#   - 景点：上海东方明珠广播电视塔
#   - 位置：景点详情页 → "园内项目"Tab（不是"门票"Tab）
#   - 服务日期：7天后
#   - 服务人数：1人
#   - 服务对象：张三（指定passenger_ids）
#   
#   需要创建的订单：
#   1) ActivityOrder - 人像跟拍服务订单（数量1人，passenger_ids: [张三.id]）
#   2) ActivityOrder - 服装租赁+化妆造型订单（数量1人，passenger_ids: [张三.id]）
#   两个订单的服务日期相同，都是7天后，服务对象都是张三。
#   
#   注意：这是景点内项目（AttractionActivity），不是门票（Ticket）。
#
# 业务流程（7个关键步骤）：
#   1. 进入景点页面：搜索上海东方明珠广播电视塔景点
#   2. 切换到"园内项目"Tab（不是"门票"Tab）
#   3. 查找摄影相关活动服务（景点内项目）
#   4. 选择"人像跟拍服务"活动（688元）
#   5. 选择"服装租赁+化妆造型"活动（388元）
#   6. 创建人像跟拍活动订单（服务日期7天后，1人）
#   7. 创建服装化妆活动订单（同一服务日期，1人）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解摄影套餐的服务组合：人像跟拍+服装租赁+化妆造型
#   2. 需要创建2个独立的活动订单（ActivityOrder）
#   3. 需要计算正确的服务日期（7天后）
#   4. 需要指定服务对象为张三（passenger_ids字段）
#   5. 需要确保两个订单的日期、人数、服务对象一致
#   6. 需要验证每个订单的状态和价格有效性
#
# 评分标准（6项，总计100分）：
#   - 创建了摄影跟拍服务订单（第1个服务项目） (20%)
#   - 景点正确（上海东方明珠广播电视塔） (10%)
#   - 创建了服装租赁+化妆造型订单（第2个服务项目） (30%)
#   - 服务日期正确（7天后，两个订单同一日期） (20%)
#   - 服务对象正确（张三，两个订单都是张三） (10%)
#   - 人数正确（每个订单都是1人） (10%)
module V301V350
  class V310BookPortraitPhotographyCostumeMakeupValidator < BaseValidator
    self.validator_id = 'v310_book_portrait_photography_costume_makeup_validator'
    self.task_id = '7230b4f9-7181-49ba-9478-979b313bdbca'
    self.title = '预订门票-上海东方明珠园内项目·人像摄影套餐（给张三预订，7天后，2个服务项目：跟拍+服装化妆）'
    self.description = '预订上海东方明珠广播电视塔景点内项目（园内项目）的人像摄影套餐，7天后，给张三预订，包含人像跟拍服务、服装租赁和化妆造型'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passenger from demo_user
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # Expected passenger
      @expected_passenger_name = @zhangsan.name
      
      @service_date = Date.current + 7.days
      @participant_count = 1
      @attraction_name = '上海东方明珠广播电视塔'
      
      # 查找上海东方明珠（适合摄影的地标景点）
      @attraction = Attraction
        .where(name: @attraction_name, data_version: 0)
        .first
      
      raise "未找到景点：#{@attraction_name}" unless @attraction
      
      # 查找摄影相关活动
      @photography_activity = @attraction.attraction_activities
        .where(data_version: 0)
        .where('name LIKE ?', '%人像跟拍%')
        .first
      raise "未找到人像跟拍活动" unless @photography_activity
      
      @costume_activity = @attraction.attraction_activities
        .where(data_version: 0)
        .where('name LIKE ?', '%服装%')
        .first
      raise "未找到服装租赁活动" unless @costume_activity
      
      {
        task: "请预订上海东方明珠广播电视塔景点内项目（园内项目）的专业摄影服务（7天后的#{@service_date.strftime('%Y年%m月%d日')}，给张三预订），包含人像跟拍、服装租赁和化妆造型。",
        requirements: {
          attraction: @attraction_name,
          service_date: @service_date,
          participant_count: @participant_count,
          services: ['人像跟拍', '服装租赁', '化妆造型']
        },
        hint: "需要预订2个不同的活动服务项目：人像跟拍服务（1人）+ 服装化妆服务（1人）。每个订单都要指定服务对象是张三（passenger_ids字段）。"
      }
    end
    
    def verify
      add_assertion "创建了摄影服务订单", weight: 20 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到活动订单"
        @photography_order = all_activity_orders.first
        expect(@photography_order).not_to be_nil, "未找到摄影服务订单"
      end
      
      return if @photography_order.nil?
      
      add_assertion "景点正确（上海东方明珠广播电视塔）", weight: 10 do
        expect(@photography_order.attraction_activity.attraction.name).to eq(@attraction_name),
          "景点错误。期望: #{@attraction_name}，实际: #{@photography_order.attraction_activity.attraction.name}"
      end
      
      add_assertion "创建了服装租赁订单（额外活动）", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders.size).to be >= 2,
          "活动订单数量不足。期望至少2个服务项目订单（人像跟拍+服装化妆，每个1人），实际找到#{all_activity_orders.size}个订单"
        
        @costume_order = all_activity_orders[1]
        expect(@costume_order).not_to be_nil, "未找到服装租赁订单（第2个服务项目）"
      end
      
      add_assertion "服务日期正确（7天后）", weight: 20 do
        expect(@photography_order.visit_date).to eq(@service_date),
          "摄影服务日期错误。期望: #{@service_date}（7天后），实际: #{@photography_order.visit_date}"
        
        if @costume_order
          expect(@costume_order.visit_date).to eq(@service_date),
            "服装租赁日期错误。期望: #{@service_date}（7天后），实际: #{@costume_order.visit_date}"
        end
      end
      
      add_assertion "服务对象正确（张三）", weight: 10 do
        # 验证第一个订单的passenger_ids
        expect(@photography_order.passenger_ids).not_to be_nil, "摄影订单未指定服务对象（passenger_ids为空）"
        expect(@photography_order.passenger_ids.size).to eq(1), "摄影订单服务对象数量错误（应为1人）"
        
        passenger_id = @photography_order.passenger_ids.first
        passenger = Passenger.find_by(id: passenger_id, data_version: 0)
        expect(passenger).not_to be_nil, "未找到服务对象乘客记录（passenger_id=#{passenger_id}）"
        expect(passenger.name).to eq(@expected_passenger_name),
          "服务对象错误。期望: #{@expected_passenger_name}，实际: #{passenger.name}"
        
        # 验证第二个订单的passenger_ids与第一个一致
        if @costume_order
          expect(@costume_order.passenger_ids).to eq(@photography_order.passenger_ids),
            "两个服务项目的服务对象应该相同（都是张三）"
        end
      end
      
      add_assertion "人数正确（1人）", weight: 10 do
        expect(@photography_order.quantity).to eq(@participant_count),
          "摄影服务人数错误。期望: #{@participant_count}人，实际: #{@photography_order.quantity}人"
        
        if @costume_order
          expect(@costume_order.quantity).to eq(@participant_count),
            "服装租赁人数错误。期望: #{@participant_count}人，实际: #{@costume_order.quantity}人"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 直接使用张三作为服务对象
      passenger_ids = [@zhangsan.id]
      
      # 1. 创建摄影服务订单（指定服务对象为张三）
      photography_activity = @photography_activity
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: photography_activity,
        visit_date: @service_date,
        quantity: @participant_count,
        passenger_ids: passenger_ids,  # 指定服务对象为张三
        total_price: photography_activity.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建服装租赁+化妆造型订单（同样是张三）
      costume_activity = @costume_activity
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: costume_activity,
        visit_date: @service_date,
        quantity: @participant_count,
        passenger_ids: passenger_ids,  # 同样是张三
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
        attraction_name: @attraction_name,
        attraction_id: @attraction&.id,
        photography_activity_id: @photography_activity&.id,
        costume_activity_id: @costume_activity&.id,
        expected_passenger_name: @expected_passenger_name
      }
    end
    
    def restore_from_state(data)
      @service_date = Date.parse(data['service_date'])
      @participant_count = data['participant_count']
      @attraction_name = data['attraction_name'] || '上海东方明珠广播电视塔'
      @expected_passenger_name = data['expected_passenger_name']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @photography_activity = AttractionActivity.find(data['photography_activity_id']) if data['photography_activity_id']
      @costume_activity = AttractionActivity.find(data['costume_activity_id']) if data['costume_activity_id']
    end
  end
end
