# frozen_string_literal: true

require_relative '../base_validator'

# V311: 预订登山门票+向导装备+山顶住宿
#
# 任务描述:
#   用户需要预订登山服务套餐，包含景点门票、登山向导+装备租赁活动、山顶住宿
#
# 评分标准:
#   - 创建门票订单+景点正确+门票类型 (35%)
#   - 创建活动订单+活动名称 (20%)
#   - 创建酒店订单+住客信息 (20%)
#   - 日期和人数正确 (25%)
module V301V350
  class V311BookMountainGuideEquipmentAccommodationValidator < BaseValidator
    self.validator_id = 'v311_book_mountain_guide_equipment_accommodation_validator'
    self.task_id = 'd31ed871-6c15-42f0-8fd0-3dfbeddca35e'
    self.title = '给刘强和陈静预订华山登山套餐（6天后，2人，含门票+向导+住宿）'
    self.description = '刘强和陈静想6天后去华山登山，需2人，要门票、登山向导+装备租赁和山顶住宿1晚'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for mountain climbing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
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
      # 断言1: 创建了景点门票订单 (15%)
      add_assertion "创建了景点门票订单（登山门票）", weight: 15 do
        @ticket_order = TicketOrder
          .joins(ticket: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@ticket_order).not_to be_nil, "未找到景点门票订单"
      end
      
      return if @ticket_order.nil?
      
      # 断言2: 景点正确（华山） (10%)
      add_assertion "景点正确（华山）", weight: 10 do
        expect(@ticket_order.ticket.attraction.name).to eq('华山'),
          "景点错误。期望: 华山, 实际: #{@ticket_order.ticket.attraction.name}"
      end
      
      # 断言3: 门票类型正确（成人票） (5%)
      add_assertion "门票类型正确（成人票）", weight: 5 do
        expect(@ticket_order.ticket.ticket_type).to eq('adult'),
          "门票类型错误。期望: adult（成人票）, 实际: #{@ticket_order.ticket.ticket_type}"
      end
      
      # 断言4: 门票游玩日期正确 (8%)
      add_assertion "门票游玩日期正确（#{@travel_date.strftime('%Y-%m-%d')}）", weight: 8 do
        expect(@ticket_order.visit_date).to eq(@travel_date),
          "门票游玩日期错误。期望: #{@travel_date}（6天后）, 实际: #{@ticket_order.visit_date}"
      end
      
      # 断言5: 门票数量正确 (5%)
      add_assertion "门票数量正确（#{@participant_count}张）", weight: 5 do
        expect(@ticket_order.quantity).to eq(@participant_count),
          "门票数量错误。期望: #{@participant_count}张, 实际: #{@ticket_order.quantity}张"
      end
      
      # 断言6: 门票游客信息正确（刘强+陈静） (7%)
      add_assertion "门票游客信息正确（刘强+陈静）", weight: 7 do
        passengers = @ticket_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "门票游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "门票游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言7: 联系人信息正确（刘强或陈静） (8%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 8 do
        expect(@expected_contact_names).to include(@ticket_order.contact_name),
          "联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{@ticket_order.contact_name}"
        expected_phone = @expected_contact_phones[@ticket_order.contact_name]
        expect(@ticket_order.contact_phone).to eq(expected_phone),
          "联系电话错误。期望: #{expected_phone}, 实际: #{@ticket_order.contact_phone}"
      end
      
      # 断言8: 创建了景点活动订单 (12%)
      add_assertion "创建了景点活动订单（登山向导+装备租赁）", weight: 12 do
        @activity_order = ActivityOrder
          .joins(attraction_activity: :attraction)
          .where(attractions: { id: @attraction.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@activity_order).not_to be_nil, "未找到景点活动订单（登山向导+装备）"
      end
      
      return if @activity_order.nil?
      
      # 断言9: 活动名称正确（包含登山/向导/装备） (5%)
      add_assertion "活动名称正确（包含登山/向导/装备）", weight: 5 do
        activity_name = @activity_order.attraction_activity.name
        expect(activity_name).to match(/登山|向导|装备/),
          "活动名称不符合。期望包含: 登山/向导/装备, 实际: #{activity_name}"
      end
      
      # 断言10: 活动日期正确 (5%)
      add_assertion "活动日期正确（#{@travel_date.strftime('%Y-%m-%d')}）", weight: 5 do
        expect(@activity_order.visit_date).to eq(@travel_date),
          "活动游玩日期错误。期望: #{@travel_date}（6天后）, 实际: #{@activity_order.visit_date}"
      end
      
      # 断言11: 活动人数正确 (5%)
      add_assertion "活动人数正确（#{@participant_count}人）", weight: 5 do
        expect(@activity_order.quantity).to eq(@participant_count),
          "活动人数错误。期望: #{@participant_count}人, 实际: #{@activity_order.quantity}人"
      end
      
      # 断言12: 活动游客信息正确（刘强+陈静） (7%)
      add_assertion "活动游客信息正确（刘强+陈静）", weight: 7 do
        passengers = @activity_order.passengers.to_a
        expect(passengers.size).to eq(2),
          "活动游客数量错误。期望: 2人（刘强+陈静），实际: #{passengers.size}人"
        
        passenger_names = passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "活动游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言13: 创建了酒店订单 (8%)
      add_assertion "创建了酒店订单（山顶住宿）", weight: 8 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（山顶住宿）"
      end
      
      return if @hotel_booking.nil?
      
      # 断言14: 住客信息正确（刘强或陈静） (8%)
      add_assertion "住客信息正确（刘强或陈静）", weight: 8 do
        expect(@expected_contact_names).to include(@hotel_booking.guest_name),
          "住客姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{@hotel_booking.guest_name}"
        expected_phone = @expected_contact_phones[@hotel_booking.guest_name]
        expect(@hotel_booking.guest_phone).to eq(expected_phone),
          "联系电话错误。期望: #{expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言15: 酒店入住日期正确 (5%)
      add_assertion "酒店入住日期正确（#{@travel_date.strftime('%Y-%m-%d')}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@travel_date),
          "酒店入住日期错误。期望: #{@travel_date}（6天后）, 实际: #{@hotel_booking.check_in_date}"
        
        expected_checkout = @travel_date + @nights
        expect(@hotel_booking.check_out_date).to eq(expected_checkout),
          "酒店退房日期错误。期望: #{expected_checkout}（住#{@nights}晚）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言16: 酒店入住人数正确 (2%)
      add_assertion "酒店入住人数正确（#{@participant_count}人）", weight: 2 do
        expect(@hotel_booking.adults_count).to eq(@participant_count),
          "酒店入住人数错误。期望: #{@participant_count}人, 实际: #{@hotel_booking.adults_count}人"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the couple as contact
      contact_person = [@liuqiang, @chenjing].sample
      
      # 1. 创建景点门票订单（登山门票） - Use existing passenger phone
      TicketOrder.create!(
        user: user,
        ticket: @ticket,
        visit_date: @travel_date,
        quantity: @participant_count,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联游客信息
        contact_name: contact_person.name,
        contact_phone: contact_person.phone,
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
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联游客信息
        total_price: @climbing_activity.current_price * @participant_count,
        insurance_type: 'basic',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建酒店订单（山顶住宿） - Use existing passenger info
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
        guest_name: contact_person.name,
        guest_phone: contact_person.phone,
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
        hotel_room_id: @hotel_room&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @nights = data['nights']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @ticket = Ticket.find(data['ticket_id']) if data['ticket_id']
      @climbing_activity = AttractionActivity.find(data['climbing_activity_id']) if data['climbing_activity_id']
      @hotel = Hotel.find(data['hotel_id']) if data['hotel_id']
      @hotel_room = HotelRoom.find(data['hotel_room_id']) if data['hotel_room_id']
    end
  end
end
