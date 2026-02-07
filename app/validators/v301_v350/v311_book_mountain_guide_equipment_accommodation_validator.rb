# frozen_string_literal: true

require_relative '../base_validator'

# V311: 预订登山门票+向导装备+山顶住宿
#
# 任务描述:
#   用户需要预订登山服务套餐，包含景点门票、登山向导+装备租赁活动、山顶住宿
#
# 评分标准:
#   - 创建了景点门票订单（登山门票）(25%)
#   - 创建了景点活动订单（登山向导+装备租赁）(35%)
#   - 创建了酒店订单（山顶住宿）(25%)
#   - 订单状态和价格有效 (15%)
module V301V350
  class V311BookMountainGuideEquipmentAccommodationValidator < BaseValidator
    self.validator_id = 'v311_book_mountain_guide_equipment_accommodation_validator'
    self.task_id = 'd31ed871-6c15-42f0-8fd0-3dfbeddca35e'
    self.title = '预订6天后2人华山登山套餐（门票+向导装备活动+山顶住宿1晚）'
    self.description = '用户需要6天后去华山，2人参与，预订登山服务套餐，包含景点门票、登山向导+装备租赁活动、山顶住宿1晚，需创建景点门票订单、景点活动订单、酒店订单，订单状态和价格有效'
    self.timeout_seconds = 300
    
    def prepare
      @travel_date = Date.current + 6.days
      @participant_count = 2
      @nights = 1
      
      # 固定地点为华山
      @attraction = Attraction
        .joins(:tickets, :attraction_activities)
        .where(name: '华山', data_version: 0)
        .where(tickets: { ticket_type: 'adult', data_version: 0 })
        .where(attraction_activities: { data_version: 0 })
        .first
      
      raise "未找到华山景点" unless @attraction
      
      # 查找华山景点门票（成人票）
      @ticket = @attraction.tickets.where(ticket_type: 'adult', data_version: 0).first
      raise "未找到华山的门票" unless @ticket
      
      # 查找登山活动（向导+装备租赁）
      @climbing_activity = @attraction.attraction_activities
        .where("name LIKE ? OR name LIKE ? OR name LIKE ?", '%登山%', '%向导%', '%装备%')
        .where(data_version: 0)
        .first
      
      raise "未找到华山的登山活动" unless @climbing_activity
      
      # 查找酒店（山顶住宿）
      @hotel = Hotel.where(data_version: 0).order(Arel.sql('RANDOM()')).first
      raise "未找到可用酒店" unless @hotel
      
      @hotel_room = @hotel.hotel_rooms.where(data_version: 0).first
      raise "未找到#{@hotel.name}的可用房间" unless @hotel_room
      
      {
        task: "请预订华山登山服务（#{@travel_date.strftime('%Y年%m月%d日')}，#{@participant_count}人），包含景点门票、登山向导+装备租赁活动、山顶住宿#{@nights}晚。",
        requirements: {
          attraction: '华山',
          travel_date: @travel_date,
          participant_count: @participant_count,
          nights: @nights,
          ticket: @ticket.name,
          climbing_activity: @climbing_activity.name,
          hotel: @hotel.name
        },
        hint: "需要预订华山景点门票、景点活动（登山向导+装备）、酒店住宿。"
      }
    end
    
    def verify
      add_assertion "创建了景点门票订单（登山门票）", weight: 20 do
        @ticket_order = TicketOrder
          .joins(ticket: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@ticket_order).not_to be_nil, "未找到景点门票订单"
      end
      
      return if @ticket_order.nil?
      
      add_assertion "创建了景点活动订单（登山向导+装备租赁）", weight: 20 do
        @activity_order = ActivityOrder
          .joins(attraction_activity: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@activity_order).not_to be_nil, "未找到景点活动订单（登山向导+装备）"
      end
      
      add_assertion "创建了酒店订单（山顶住宿）", weight: 20 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（山顶住宿）"
      end
      
      add_assertion "门票和活动订单时间正确（#{@travel_date}）", weight: 15 do
        expect(@ticket_order.visit_date).to eq(@travel_date),
          "门票游玩日期错误。期望: #{@travel_date}（6天后），实际: #{@ticket_order.visit_date}"
        
        if @activity_order
          expect(@activity_order.visit_date).to eq(@travel_date),
            "活动游玩日期错误。期望: #{@travel_date}（6天后），实际: #{@activity_order.visit_date}"
        end
      end
      
      add_assertion "酒店入住日期正确（#{@travel_date}）", weight: 10 do
        if @hotel_booking
          expect(@hotel_booking.check_in_date).to eq(@travel_date),
            "酒店入住日期错误。期望: #{@travel_date}（6天后），实际: #{@hotel_booking.check_in_date}"
          
          expected_checkout = @travel_date + @nights
          expect(@hotel_booking.check_out_date).to eq(expected_checkout),
            "酒店退房日期错误。期望: #{expected_checkout}（住#{@nights}晚），实际: #{@hotel_booking.check_out_date}"
        end
      end
      
      add_assertion "人数正确（#{@participant_count}人）", weight: 10 do
        expect(@ticket_order.quantity).to eq(@participant_count),
          "门票数量错误。期望: #{@participant_count}张，实际: #{@ticket_order.quantity}张"
        
        if @activity_order
          expect(@activity_order.quantity).to eq(@participant_count),
            "活动人数错误。期望: #{@participant_count}人，实际: #{@activity_order.quantity}人"
        end
        
        if @hotel_booking
          expect(@hotel_booking.adults_count).to eq(@participant_count),
            "酒店入住人数错误。期望: #{@participant_count}人，实际: #{@hotel_booking.adults_count}人"
        end
      end
      
      add_assertion "订单状态和价格有效", weight: 5 do
        expect(@ticket_order.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@ticket_order.total_price).to be > 0
        
        if @activity_order
          expect(@activity_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@activity_order.total_price).to be > 0
        end
        
        if @hotel_booking
          expect(@hotel_booking.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@hotel_booking.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建景点门票订单（登山门票）
      TicketOrder.create!(
        user: user,
        ticket: @ticket,
        visit_date: @travel_date,
        quantity: @participant_count,
        contact_phone: '13800138000',
        total_price: @ticket.current_price * @participant_count,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建景点活动订单（登山向导+装备租赁）
      ActivityOrder.create!(
        user: user,
        attraction_activity: @climbing_activity,
        visit_date: @travel_date,
        quantity: @participant_count,
        total_price: @climbing_activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建酒店订单（山顶住宿）
      check_in_date = @travel_date
      check_out_date = check_in_date + @nights
      
      HotelBooking.create!(
        user: user,
        hotel: @hotel,
        hotel_room: @hotel_room,
        check_in_date: check_in_date,
        check_out_date: check_out_date,
        rooms_count: 1,
        adults_count: @participant_count,
        children_count: 0,
        guest_name: user.name,
        guest_phone: '13800138000',
        total_price: @hotel_room.price * @nights,
        payment_method: '花呗',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        nights: @nights,
        attraction_id: @attraction&.id,
        ticket_id: @ticket&.id,
        climbing_activity_id: @climbing_activity&.id,
        hotel_id: @hotel&.id,
        hotel_room_id: @hotel_room&.id
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @nights = data['nights']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      @hotel = Hotel.find(data['hotel_id']) if data['hotel_id']
      @hotel_room = HotelRoom.find(data['hotel_room_id']) if data['hotel_room_id']
    end
  end
end
