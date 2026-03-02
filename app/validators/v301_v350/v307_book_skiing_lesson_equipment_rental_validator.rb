# frozen_string_literal: true

require_relative '../base_validator'

# V307: 预订张家口崇礼万龙滑雪场门票+装备租赁（3天后，2人）
#
# 任务描述:
#   用户需要在3天后为2人预订张家口崇礼万龙滑雪场的滑雪服务，包含：
#   1) 滑雪场门票订单（TicketOrder）
#   2) 滑雪装备租赁活动订单（ActivityOrder）
#   确保景点、日期和人数正确
#
# 评分标准:
#   - 创建了门票订单 (20%)
#   - 景点正确（崇礼万龙滑雪场） (15%)
#   - 创建了滑雪装备租赁活动订单 (25%)
#   - 两个订单的日期均正确（3天后） (15%)
#   - 联系电话正确（刘强） (10%)
#   - 两个订单的人数均正确（2人） (15%)
module V301V350
  class V307BookSkiingLessonEquipmentRentalValidator < BaseValidator
    self.validator_id = 'v307_book_skiing_lesson_equipment_rental_validator'
    self.task_id = '72e6f61b-18de-4434-a053-2297fd7be1b9'
    self.title = '给张三刘强和陈静想3天后去张家口崇礼万龙滑雪场滑雪，需2人，要门票和装备租赁'
    self.description = '刘强和陈静想3天后去张家口崇礼万龙滑雪场滑雪，需2人，要门票和装备租赁'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for skiing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (one of the couple can be contact)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      @visit_date = Date.current + 3.days
      @participant_count = 2
      @attraction_name = '崇礼万龙滑雪场'
      @city = '张家口'
      @activity_name = '滑雪装备租赁（全套）'
      
      # 查找崇礼万龙滑雪场
      @attraction = Attraction.find_by(name: @attraction_name, city: @city, data_version: 0)
      raise "未找到#{@attraction_name}" unless @attraction
      
      # 查找门票
      @ticket = @attraction.tickets.where(data_version: 0).first
      raise "未找到#{@attraction_name}的门票" unless @ticket
      
      # 查找滑雪装备租赁活动
      @equipment_activity = @attraction.attraction_activities
        .where("name LIKE ?", '%滑雪装备租赁%')
        .where(data_version: 0)
        .first
      raise "未找到#{@attraction_name}的滑雪装备租赁活动" unless @equipment_activity
      
      {
        task: "请预订#{@city}#{@attraction_name}的滑雪服务（#{@visit_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含滑雪场门票和滑雪装备租赁。",
        requirements: {
          attraction: @attraction_name,
          city: @city,
          visit_date: @visit_date,
          participant_count: @participant_count,
          services: ['景区门票', '滑雪装备租赁']
        },
        hint: "需要同时预订景区门票和滑雪装备租赁活动。"
      }
    end
    
    def verify
      add_assertion "创建了门票订单", weight: 20 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @ticket_orders = all_ticket_orders
        expect(@ticket_orders).not_to be_empty, "未找到门票订单"
      end
      
      return if @ticket_orders.nil? || @ticket_orders.empty?
      
      add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}，实际: #{order.ticket.attraction.name}"
        end
      end
      
      add_assertion "创建了滑雪装备租赁活动订单", weight: 25 do
        all_activity_orders = ActivityOrder
          .joins(:attraction_activity)
          .includes(:attraction_activity)
          .where("attraction_activities.name LIKE ?", '%滑雪装备租赁%')
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @equipment_orders = all_activity_orders.select do |order|
          order.attraction_activity.attraction_id == @attraction.id
        end
        
        expect(@equipment_orders).not_to be_empty, "未找到#{@attraction_name}的滑雪装备租赁活动订单"
      end
      
      add_assertion "两个订单的日期均正确（3天后）", weight: 15 do
        @ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date), 
            "门票订单日期错误。期望: #{@visit_date}（3天后）, 实际: #{order.visit_date}"
        end
        
        @equipment_orders&.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "装备租赁订单日期错误。期望: #{@visit_date}（3天后）, 实际: #{order.visit_date}"
        end
      end
      
      add_assertion "联系电话正确（刘强或陈静）", weight: 10 do
        @ticket_orders.each do |order|
          expected_phones = @expected_contact_phones.values
          expect(expected_phones).to include(order.contact_phone),
            "联系电话错误。期望: #{expected_phones.join('或')}, 实际: #{order.contact_phone}"
        end
      end
      
      add_assertion "两个订单的人数均正确（2人）", weight: 15 do
        @ticket_orders.each do |order|
          expect(order.quantity).to eq(@participant_count),
            "门票订单人数错误。期望: #{@participant_count}人, 实际: #{order.quantity}人"
        end
        
        @equipment_orders&.each do |order|
          expect(order.quantity).to eq(@participant_count),
            "装备租赁订单人数错误。期望: #{@participant_count}人, 实际: #{order.quantity}人"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 随机选择一位作为联系人
      contact_person = [@liuqiang, @chenjing].sample
      
      # 1. 创建门票订单 - Use randomly selected contact
      TicketOrder.create!(
        user: user,
        ticket: @ticket,
        contact_phone: contact_person.phone,
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: @ticket.current_price * @participant_count,
        insurance_type: 'none',
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建滑雪装备租赁活动订单
      ActivityOrder.create!(
        user: user,
        attraction_activity: @equipment_activity,
        passenger_name: contact_person.name,
        contact_phone: contact_person.phone,
        visit_date: @visit_date,
        quantity: @participant_count,
        total_price: @equipment_activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        visit_date: @visit_date.to_s,
        participant_count: @participant_count,
        attraction_name: @attraction_name,
        city: @city,
        activity_name: @activity_name,
        attraction_id: @attraction&.id,
        ticket_id: @ticket&.id,
        equipment_activity_id: @equipment_activity&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @visit_date = Date.parse(data['visit_date'])
      @participant_count = data['participant_count']
      @attraction_name = data['attraction_name']
      @city = data['city']
      @activity_name = data['activity_name']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @equipment_activity = AttractionActivity.find(data['equipment_activity_id']) if data['equipment_activity_id']
    end
  end
end