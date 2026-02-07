# frozen_string_literal: true

require_relative '../base_validator'

# V308: 预订蜈支洲岛潜水服务（4天后，2人）
#
# 任务描述:
#   用户需要预订蜈支洲岛的潜水服务（4天后，2人），包含景区门票、潜水教学+体验和水下摄影服务
#
# 评分标准:
#   - 购买了景区门票(25%)
#   - 预订了潜水活动(30%)
#   - 预订了摄影服务(25%)
#   - 活动日期正确（4天后）(15%)
#   - 订单状态和价格有效 (5%)
module V301V350
  class V308BookDivingLessonPhotographyValidator < BaseValidator
    self.validator_id = 'v308_book_diving_lesson_photography_validator'
    self.task_id = '9a83baa7-a2f8-4e7d-bb5c-86a23bf7507a'
    self.title = '预订蜈支洲岛潜水服务（4天后，2人）'
    self.description = '用户需要预订蜈支洲岛的潜水服务（4天后，2人），包含景区门票、潜水教学+体验和水下摄影服务'
    self.timeout_seconds = 300
    
    def prepare
      @visit_date = Date.current + 4.days
      @participant_count = 2
      
      # 查找蜈支洲岛景点（著名潜水胜地）
      # 注意：DataVersionable concern 的 default_scope 会自动过滤 data_version
      @attraction = Attraction.find_by!(name: '蜈支洲岛')
      
      # 查找门票和潜水相关活动
      @adult_ticket = @attraction.tickets.find_by(ticket_type: 'adult')
      @diving_activity = @attraction.attraction_activities.find_by(name: '潜水教学+体验')
      @photography_activity = @attraction.attraction_activities.find_by(name: '水下摄影服务')
      
      {
        task: "请预订蜈支洲岛的潜水服务（#{@visit_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含景区门票、潜水教学+体验和水下摄影服务。",
        requirements: {
          attraction: '蜈支洲岛',
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['景区门票', '潜水教学+体验', '水下摄影服务']
        },
        hint: "需要购买景区门票，并预订潜水体验和水下摄影服务。"
      }
    end
    
    def verify
      # 断言1: 购买了景区门票
      add_assertion "购买了景区门票（#{@attraction.name}）", weight: 25 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到#{@attraction.name}的门票订单"
        @ticket_order = all_ticket_orders.first
        expect(@ticket_order).not_to be_nil, "未购买景区门票"
        expect(@ticket_order.quantity).to eq(@participant_count),
          "门票数量错误。期望: #{@participant_count}张，实际: #{@ticket_order.quantity}张"
      end
      
      return if @ticket_order.nil?
      
      # 断言2: 预订了潜水活动
      add_assertion "预订了潜水活动（潜水教学+体验）", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders).not_to be_empty, "未找到#{@attraction.name}的活动订单"
        @diving_order = all_activity_orders.find { |o| o.attraction_activity.name.include?('潜水') }
        expect(@diving_order).not_to be_nil, "未预订潜水活动"
      end
      
      return if @diving_order.nil?
      
      # 断言3: 预订了摄影服务
      add_assertion "预订了摄影服务（水下摄影服务）", weight: 25 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :asc)
          .to_a
        
        expect(all_activity_orders.size).to be >= 2,
          "活动订单数量不足。期望至少2个活动（潜水+摄影），实际找到#{all_activity_orders.size}个"
        
        @photography_order = all_activity_orders.find { |o| o.attraction_activity.name.include?('摄影') }
        expect(@photography_order).not_to be_nil, "未预订摄影服务"
      end
      
      # 断言4: 游玩日期正确（4天后）
      add_assertion "游玩日期正确（#{@visit_date}）", weight: 15 do
        expect(@ticket_order.visit_date).to eq(@visit_date),
          "门票游玩日期错误。期望: #{@visit_date}（4天后），实际: #{@ticket_order.visit_date}"
        
        expect(@diving_order.visit_date).to eq(@visit_date),
          "潜水活动日期错误。期望: #{@visit_date}（4天后），实际: #{@diving_order.visit_date}"
        
        if @photography_order
          expect(@photography_order.visit_date).to eq(@visit_date),
            "摄影服务日期错误。期望: #{@visit_date}（4天后），实际: #{@photography_order.visit_date}"
        end
      end
      
      # 断言5: 订单状态和价格有效
      add_assertion "订单状态和价格有效", weight: 5 do
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'confirmed']),
          "门票订单状态无效: #{@ticket_order.status}"
        expect(@ticket_order.total_price).to be > 0,
          "门票订单总价无效: #{@ticket_order.total_price}"
        
        expect(@diving_order.status).to be_in(['pending', 'paid', 'confirmed']),
          "潜水订单状态无效: #{@diving_order.status}"
        expect(@diving_order.total_price).to be > 0,
          "潜水订单总价无效: #{@diving_order.total_price}"
        
        if @photography_order
          expect(@photography_order.status).to be_in(['pending', 'paid', 'confirmed']),
            "摄影订单状态无效: #{@photography_order.status}"
          expect(@photography_order.total_price).to be > 0,
            "摄影订单总价无效: #{@photography_order.total_price}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建门票订单（TicketOrder）
      adult_ticket = @adult_ticket || @attraction.tickets.find_by!(ticket_type: 'adult')
      
      TicketOrder.create!(
        user: user,
        ticket: adult_ticket,
        visit_date: @visit_date,
        quantity: @participant_count,
        contact_phone: '13800138000',
        total_price: adult_ticket.current_price * @participant_count,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建潜水活动订单（ActivityOrder）
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
        contact_phone: '13800138000',
        total_price: diving_activity.current_price * @participant_count,
        insurance_type: 'premium',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建摄影服务订单（ActivityOrder）
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
        contact_phone: '13800138000',
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
        adult_ticket_id: @adult_ticket&.id,
        diving_activity_id: @diving_activity&.id,
        photography_activity_id: @photography_activity&.id
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @adult_ticket = Ticket.find(data['adult_ticket_id']) if data['adult_ticket_id']
      @diving_activity = AttractionActivity.find(data['diving_activity_id']) if data['diving_activity_id']
      @photography_activity = AttractionActivity.find(data['photography_activity_id']) if data['photography_activity_id']
    end
  end
end
