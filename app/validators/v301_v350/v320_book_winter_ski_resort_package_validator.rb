# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例320: 预订张家口崇礼万龙滑雪场全天票+万龙度假酒店滑雪主题大床房（刘强、陈静，45天后，2人，2晚）
#
# 任务描述:
#   刘强和陈静想在45天后去张家口崇礼滑雪度假。
#   要求：崇礼万龙滑雪场全天票2张（成人票）+ 崇礼万龙度假酒店滑雪主题大床房（45天后入住，2晚，1间房，2成人）。
#   Agent 需要创建两个订单：
#   1) 滑雪票订单（TicketOrder）- 崇礼万龙滑雪场全天票，2张成人票，45天后，游客刘强+陈静
#   2) 滑雪场酒店订单（HotelBooking）- 崇礼万龙度假酒店滑雪主题大床房，45天后入住，2晚，1间房，2成人
#   联系人使用刘强或陈静的信息。
#
# 业务流程（7个关键步骤）：
#   1. 搜索张家口崇礼地区的滑雪场景点
#   2. 查找崇礼万龙滑雪场的全天票（成人票）
#   3. 创建滑雪票订单（2张成人票，游客刘强+陈静，45天后游玩）
#   4. 搜索崇礼地区的滑雪主题酒店
#   5. 查找崇礼万龙度假酒店的滑雪主题大床房
#   6. 确定酒店入住日期（45天后入住，2晚）
#   7. 创建酒店订单（1间滑雪主题大床房，2成人，45天后入住2晚）
#
# 复杂度分析（7个关键点）：
#   1. 需要创建两个订单：TicketOrder（滑雪票）+ HotelBooking（滑雪场酒店）
#   2. 需要准确匹配滑雪场名称（崇礼万龙滑雪场）和票型（全天票）
#   3. 需要准确匹配酒店名称（崇礼万龙度假酒店）和房型（滑雪主题大床房）
#   4. 需要验证滑雪票数量（2张成人票）和游客信息（刘强+陈静2人）
#   5. 需要验证滑雪日期与酒店入住日期一致（都是45天后）
#   6. 需要验证酒店住宿天数（2晚）和人数（2成人）
#   7. 需要处理情侣出游场景（2人无儿童，1间大床房）
#
# 评分标准（11项，总计100%）:
#   - 创建了滑雪票订单（崇礼万龙滑雪场） (12%)
#   - 滑雪场正确（崇礼万龙滑雪场） (8%)
#   - 门票类型和数量正确（2张成人票） (8%)
#   - 滑雪票游客信息正确（刘强+陈静） (7%)
#   - 滑雪日期正确（45天后） (8%)
#   - 创建了酒店订单（崇礼万龙度假酒店） (12%)
#   - 酒店名称和房型正确（崇礼万龙度假酒店 滑雪主题大床房） (8%)
#   - 入住退房日期正确（#{@check_in_date.strftime('%Y-%m-%d')}至#{@check_out_date.strftime('%Y-%m-%d')}，2晚） (8%)
#   - 房间数和人数正确（1间房，2成人） (5%)
#   - 联系人信息正确（刘强或陈静） (15%)
#   - 订单状态和价格有效 (9%)
module V301V350
  class V320BookWinterSkiResortPackageValidator < BaseValidator
    self.validator_id = 'v320_book_winter_ski_resort_package_validator'
    self.task_id = "fb78ecc4-1181-49ba-9b77-09a5c4368c42"
    self.title = '预订张家口崇礼万龙滑雪场全天票+万龙度假酒店滑雪主题大床房（刘强、陈静，45天后，2人，2晚）'
    self.description = '刘强和陈静想在45天后去张家口崇礼滑雪度假，预订崇礼万龙滑雪场全天票2张（成人票）和崇礼万龙度假酒店滑雪主题大床房（45天后入住，2晚，1间房，2成人）'
    self.timeout_seconds = 180

    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for skiing)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      # 45天后滑雪
      @visit_date = Date.current + 45.days
      @check_in_date = @visit_date
      @check_out_date = @visit_date + 2.days
      @resort_name = "崇礼万龙滑雪场"
      @city_name = "张家口"
      @hotel_name = "崇礼万龙度假酒店"
      @room_type = "滑雪主题大床房"
      
      # 查找城市
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: "崇礼",
        data_version: 0
      )

      # 查找滑雪场景点
      @attraction = Attraction.find_by!(
        name: @resort_name,
        city: @city_name,
        data_version: 0
      )

      # 查找滑雪票（明确指定全天票）
      @ticket = Ticket.find_by!(
        attraction: @attraction,
        name: "崇礼万龙滑雪场全天票",
        ticket_type: "adult",
        data_version: 0
      )

      # 查找装备租赁活动
      @ski_equipment = @attraction.attraction_activities.find_by!(
        name: "滑雪装备租赁（全套）",
        data_version: 0
      )

      # 查找滑雪场酒店
      @hotel = Hotel.find_by!(
        name: @hotel_name,
        city: @city_name,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: @room_type,
        data_version: 0
      )

      {
        task: "请为刘强和陈静预订#{@visit_date.strftime('%Y年%m月%d日')}（45天后）的张家口崇礼#{@resort_name}全天票2张（成人票），以及#{@hotel_name}#{@room_type}（入住#{@check_in_date.strftime('%m月%d日')}至#{@check_out_date.strftime('%m月%d日')}，共2晚）。",
        requirements: {
          resort_name: @resort_name,
          city_name: @city_name,
          visit_date: @visit_date,
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          ticket_quantity: 2,
          ticket_type: '全天票（成人）',
          nights: 2,
          hotel_name: @hotel_name,
          room_type: @room_type,
          adults_count: 2
        },
        hint: "滑雪票和酒店可以分别预订，注意日期要匹配。推荐雪道：初级道→中级道→高级道逐步体验。"
      }
    end

    def verify
      # 断言1: 创建了滑雪票订单 (12%)
      add_assertion "创建了#{@resort_name}滑雪票订单", weight: 12 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @resort_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到滑雪票订单"
        
        @ticket_orders = all_ticket_orders
        expect(@ticket_orders.size).to be >= 1, "未找到滑雪票订单"
      end

      return if @ticket_orders.nil? || @ticket_orders.empty?

      # 断言2: 滑雪场正确（崇礼万龙滑雪场） (8%)
      add_assertion "滑雪场正确（#{@resort_name}）", weight: 8 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@resort_name),
            "滑雪场错误。期望: #{@resort_name}, 实际: #{order.ticket.attraction.name}"
        end
      end

      # 断言3: 门票类型和数量正确（2张成人票） (8%)
      add_assertion "门票类型和数量正确（2张成人票）", weight: 8 do
        adult_tickets = @ticket_orders.select { |o| o.ticket.ticket_type == 'adult' }
        expect(adult_tickets).not_to be_empty, "未找到成人票订单"
        
        total_quantity = @ticket_orders.sum(&:quantity)
        expect(total_quantity).to eq(2),
          "门票数量错误。期望: 2张，实际: #{total_quantity}张"
      end
      
      # 断言4: 滑雪票游客信息正确（刘强+陈静） (7%)
      add_assertion "滑雪票游客信息正确（刘强+陈静）", weight: 7 do
        all_passengers = @ticket_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(2),
          "滑雪票游客数量错误。期望: 2人（刘强+陈静），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "滑雪票游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end

      # 断言5: 滑雪日期正确（45天后） (8%)
      add_assertion "滑雪日期正确（#{@visit_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "滑雪日期错误。期望: #{@visit_date}（45天后），实际: #{order.visit_date}"
        end
      end

      # 断言6: 创建了滑雪场酒店订单 (12%)
      add_assertion "创建了#{@hotel_name}订单", weight: 12 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @city_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings
        expect(@hotel_bookings.size).to be >= 1, "未找到酒店订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言7: 酒店名称和房型正确 (8%)
      add_assertion "酒店名称和房型正确（#{@hotel_name} #{@room_type}）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel_name),
            "酒店名称错误。期望: #{@hotel_name}，实际: #{booking.hotel.name}"
          expect(booking.hotel_room.room_type).to eq(@room_type),
            "房型错误。期望: #{@room_type}，实际: #{booking.hotel_room.room_type}"
        end
      end

      # 断言8: 入住退房日期正确（2晚） (8%)
      add_assertion "入住退房日期正确（#{@check_in_date.strftime('%Y-%m-%d')}至#{@check_out_date.strftime('%Y-%m-%d')}，2晚）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}, 实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}, 实际: #{booking.check_out_date}"
          
          nights = (booking.check_out_date - booking.check_in_date).to_i
          expect(nights).to eq(2),
            "住宿天数错误。期望: 2晚，实际: #{nights}晚"
        end
      end
      
      # 断言9: 房间数和人数正确（1间房，2成人） (5%)
      add_assertion "房间数和人数正确（1间房，2成人）", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.rooms_count).to eq(1),
            "房间数错误。期望: 1间房，实际: #{booking.rooms_count}间房"
          expect(booking.adults_count).to eq(2),
            "成人数错误。期望: 2成人，实际: #{booking.adults_count}成人"
        end
      end
      
      # 断言10: 联系人信息正确（刘强或陈静） (15%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 15 do
        # 验证滑雪票订单联系人
        @ticket_orders.each do |order|
          if order.respond_to?(:contact_name) && order.contact_name.present?
            expect(@expected_contact_names).to include(order.contact_name),
              "滑雪票联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{order.contact_name}"
            expected_phone = @expected_contact_phones[order.contact_name]
            if expected_phone
              expect(order.contact_phone).to eq(expected_phone),
                "滑雪票联系电话错误。期望: #{expected_phone}, 实际: #{order.contact_phone}"
            end
          elsif order.contact_phone.present?
            expect(@expected_contact_phones.values).to include(order.contact_phone),
              "滑雪票联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{order.contact_phone}"
          end
        end
        
        # 验证酒店订单联系人
        @hotel_bookings.each do |booking|
          expect(@expected_contact_names).to include(booking.guest_name),
            "住客姓名错误。期望: #{@expected_contact_names.join('或')}，实际: #{booking.guest_name}"
          expected_phone = @expected_contact_phones[booking.guest_name]
          if expected_phone
            expect(booking.guest_phone).to eq(expected_phone),
              "酒店联系电话错误。期望: #{expected_phone}，实际: #{booking.guest_phone}"
          end
        end
      end
      
      # 断言11: 订单状态和价格有效 (9%)
      add_assertion "订单状态和价格有效", weight: 9 do
        @ticket_orders.each do |order|
          expect(['pending', 'paid', 'confirmed']).to include(order.status),
            "滑雪票订单状态无效。期望: pending/paid/confirmed，实际: #{order.status}"
          expect(order.total_price).to be > 0,
            "滑雪票订单价格无效。期望: >0，实际: #{order.total_price}"
        end
        
        @hotel_bookings.each do |booking|
          expect(['pending', 'paid', 'confirmed']).to include(booking.status),
            "酒店订单状态无效。期望: pending/paid/confirmed，实际: #{booking.status}"
          expect(booking.total_price).to be > 0,
            "酒店订单价格无效。期望: >0，实际: #{booking.total_price}"
        end
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one of the couple as contact
      contact_passenger = [@liuqiang, @chenjing].sample
      
      # 1. 创建滑雪票订单
      ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联2个游客
        contact_phone: contact_passenger.phone,
        total_price: @ticket.current_price * 2,
        status: 'paid',  # 模拟已支付状态
        data_version: @data_version  # ✅ Session-scoped
      )
      
      # 2. 创建酒店订单
      nights = (@check_out_date - @check_in_date).to_i
      base_price = @hotel_room.price * nights * 1
      hotel_booking = HotelBooking.create!(
        hotel_id: @hotel.id,
        hotel_room_id: @hotel_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: contact_passenger.name,
        guest_phone: contact_passenger.phone,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        payment_method: '花呗',
        total_price: base_price,
        status: 'paid',  # 模拟已支付状态
        data_version: @data_version  # ✅ Session-scoped
      )
      
      {
        action: 'create_ski_ticket_and_hotel',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    private

    def execution_state_data
      {
        visit_date: @visit_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        resort_name: @resort_name,
        city_name: @city_name,
        hotel_name: @hotel_name,
        room_type: @room_type,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id,
        ticket_id: @ticket&.id,
        hotel_room_id: @hotel_room&.id,
        ski_equipment_id: @ski_equipment&.id,
        liuqiang_id: @liuqiang&.id,
        chenjing_id: @chenjing&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end

    def restore_from_state(state)
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @resort_name = state['resort_name']
      @city_name = state['city_name']
      @hotel_name = state['hotel_name']
      @room_type = state['room_type']
      @expected_contact_names = state['expected_contact_names']
      @expected_contact_phones = state['expected_contact_phones']
      
      @attraction = Attraction.find(state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find(state['hotel_id']) if state['hotel_id']
      @ticket = Ticket.find(state['ticket_id']) if state['ticket_id']
      @hotel_room = HotelRoom.find(state['hotel_room_id']) if state['hotel_room_id']
      @ski_equipment = AttractionActivity.find(state['ski_equipment_id']) if state['ski_equipment_id']
      @liuqiang = Passenger.find(state['liuqiang_id']) if state['liuqiang_id']
      @chenjing = Passenger.find(state['chenjing_id']) if state['chenjing_id']
    end
  end
end