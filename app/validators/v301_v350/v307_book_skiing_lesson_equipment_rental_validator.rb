# frozen_string_literal: true

require_relative '../base_validator'

# V307: 预订滑雪教学+滑雪场门票+装备租赁
#
# 任务描述:
#   用户需要预订滑雪服务套餐，包含教学、门票和装备租赁
#
# 评分标准:
#   - 创建了景区活动订单（滑雪体验）(30%)
#   - 创建了景区门票订单 (30%)
#   - 创建了租车订单（装备租赁）(25%)
#   - 订单状态和价格有效 (15%)
module V301V350
  class V307BookSkiingLessonEquipmentRentalValidator < BaseValidator
    self.validator_id = 'v307_book_skiing_lesson_equipment_rental_validator'
    self.task_id = '72e6f61b-18de-4434-a053-2297fd7be1b9'
    self.title = '预订滑雪教学+滑雪场门票+装备租赁'
    self.description = '用户需要预订滑雪服务套餐，包含教学、门票和装备租赁'
    self.timeout_seconds = 300
    
    def prepare
      @visit_date = Date.current + 3.days
      @participant_count = 2
      
      # 查找滑雪相关景点（使用活动类型为滑雪的景点）
      skiing_activity = AttractionActivity
        .joins(:attraction)
        .where("attraction_activities.name LIKE ? OR attraction_activities.name LIKE ?", '%滑雪%', '%雪场%')
        .where(data_version: 0)
        .first
      
      @attraction = skiing_activity&.attraction || Attraction.where(data_version: 0).first
      raise "未找到滑雪相关景点" unless @attraction
      
      @activity_name = skiing_activity&.name || '滑雪教学体验'
      
      # 查找门票
      @ticket = @attraction.tickets.where(data_version: 0).first
      raise "未找到#{@attraction.name}的门票" unless @ticket
      
      # 查找租车服务（用作装备租赁）
      @car = Car.where(data_version: 0, category: 'suv').first
      @car ||= Car.where(data_version: 0).first
      raise "未找到可用车辆（装备租赁）" unless @car
      
      {
        task: "请预订#{@attraction.name}的滑雪服务（#{@visit_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含滑雪教学、门票和装备租赁。",
        requirements: {
          attraction: @attraction.name,
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['滑雪教学', '景区门票', '装备租赁']
        },
        hint: "需要同时预订活动体验、景区门票和装备租赁服务。"
      }
    end
    
    def verify
      add_assertion "创建了景区活动订单（滑雪体验）", weight: 30 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where(attraction_activities: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .to_a
        
        @activity_order = all_activity_orders.first
        expect(@activity_order).not_to be_nil, "未找到#{@attraction.name}的活动订单"
      end
      
      return if @activity_order.nil?
      
      add_assertion "创建了景区门票订单", weight: 30 do
        @ticket_order = TicketOrder
          .joins(ticket: :attraction)
          .where(tickets: { attraction_id: @attraction.id })
          .where(data_version: @data_version)
          .first
        
        expect(@ticket_order).not_to be_nil, "未找到#{@attraction.name}的门票订单"
      end
      
      add_assertion "创建了租车订单（装备租赁）", weight: 25 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到装备租赁订单（租车订单）"
      end
      
      add_assertion "订单状态和价格有效", weight: 15 do
        expect(@activity_order.status).to be_in(['pending', 'paid', 'confirmed']) if @activity_order
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'confirmed']) if @ticket_order
        expect(@car_order.status).to be_in(['pending', 'paid', 'confirmed']) if @car_order
        
        expect(@activity_order.total_price).to be > 0 if @activity_order
        expect(@ticket_order.total_price).to be > 0 if @ticket_order
        expect(@car_order.total_price).to be > 0 if @car_order
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建活动订单（滑雪教学）
      activity = @attraction.attraction_activities.where(data_version: 0).first
      activity ||= AttractionActivity.create!(
        attraction: @attraction,
        name: @activity_name,
        description: '专业滑雪教练一对一教学',
        current_price: 200,
        data_version: 0
      )
      
      ActivityOrder.create!(
        user: user,
        attraction_activity: activity,
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建门票订单
      TicketOrder.create!(
        user: user,
        ticket: @ticket,
        contact_phone: '13800138000',
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: @ticket.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建租车订单（装备租赁）
      pickup_datetime = @visit_date.to_time + 9.hours
      return_datetime = @visit_date.to_time + 18.hours
      
      CarOrder.create!(
        user: user,
        car: @car,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        total_price: @car.price_per_day,
        pickup_location: @attraction.name,
        driver_name: user.name,
        driver_id_number: '310101198001011234',
        contact_phone: '13800138000',
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
        activity_name: @activity_name,
        ticket_id: @ticket&.id,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      @activity_name = data['activity_name']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @car = Car.find(data['car_id']) if data['car_id']
    end
  end
end
