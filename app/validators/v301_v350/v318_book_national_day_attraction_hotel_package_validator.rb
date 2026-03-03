# frozen_string_literal: true

require_relative '../base_validator'

# V318: 刘强和陈静想7天后去张家界，需2人，要国家森林公园门票（2张成人票）和武陵源度假酒店豪华双床房（7天后入住，2晚，1间房）
#
# 任务描述:
#   用户需要在7天后为2人（刘强、陈静）预订张家界旅游服务，包含：
#   1) 景区门票订单（TicketOrder，张家界国家森林公园成人票2张）
#   2) 酒店订单（HotelBooking，张家界武陵源度假酒店豪华双床房，2晚，1间房）
#   确保景区、酒店、票型、房型、日期和人数正确
#
# 评分标准:
#   - 创建了门票订单（张家界国家森林公园） (12%)
#   - 景区正确（张家界国家森林公园） (8%)
#   - 门票类型和数量正确（2张成人票） (8%)
#   - 门票游客信息正确（刘强+陈静） (7%)
#   - 游玩日期正确（7天后） (8%)
#   - 创建了酒店订单（张家界武陵源度假酒店） (12%)
#   - 酒店名称正确（张家界武陵源度假酒店） (8%)
#   - 房型正确（豪华双床房） (5%)
#   - 入住退房日期正确（2晚） (8%)
#   - 房间数和人数正确（1间房，2成人） (5%)
#   - 联系人信息正确（刘强或陈静） (10%)
#   - 订单状态和价格有效 (9%)
module V301V350
  class V318BookNationalDayAttractionHotelPackageValidator < BaseValidator
    self.validator_id = 'v318_book_national_day_attraction_hotel_package_validator'
    self.task_id = "2fa37623-24e7-46f7-a054-b2c98c7c7227"
    self.title = '刘强和陈静想7天后去张家界，需2人，要国家森林公园门票（2张成人票）和武陵源度假酒店豪华双床房（7天后入住，2晚，1间房）'
    self.description = '刘强和陈静想7天后去张家界，需2人，要国家森林公园门票（2张成人票）和武陵源度假酒店豪华双床房（7天后入住，2晚，1间房）'
    self.timeout_seconds = 180

    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (couple for travel)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强 or 陈静)
      @expected_contact_names = [@liuqiang.name, @chenjing.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone
      }
      
      # 7天后入住，住2晚
      @check_in_date = Date.current + 7.days
      @check_out_date = @check_in_date + 2.days
      @visit_date = @check_in_date
      @attraction_name = "张家界国家森林公园"
      @city_name = "张家界"
      @hotel_name = "张家界武陵源度假酒店"
      @room_type = "豪华双床房"
      
      # 查找城市和目的地
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      # 查找景区
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        city: @city_name,
        data_version: 0
      )

      # 查找门票
      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "adult",
        data_version: 0
      )

      # 查找酒店
      @hotel = Hotel.find_by!(
        name: @hotel_name,
        city: @city_name,
        data_version: 0
      )

      # 查找房型
      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: @room_type,
        data_version: 0
      )

      {
        task: "请为刘强和陈静预订#{@check_in_date.strftime('%Y年%m月%d日')}（7天后）的#{@attraction_name}成人门票2张，以及#{@hotel_name}#{@room_type}（入住#{@check_in_date.strftime('%m月%d日')}至#{@check_out_date.strftime('%m月%d日')}，共2晚，1间房，2人）。",
        requirements: {
          attraction_name: @attraction_name,
          city_name: @city_name,
          visit_date: @visit_date,
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          ticket_quantity: 2,
          ticket_type: '成人票',
          nights: 2,
          hotel_name: @hotel_name,
          room_type: @room_type,
          rooms_count: 1,
          adults_count: 2
        },
        hint: "景区门票和酒店可以分别预订，注意日期要匹配。推荐游览路线：金鞭溪→袁家界→天子山→十里画廊。"
      }
    end

    def verify
      # 断言1: 创建了门票订单 (12%)
      add_assertion "创建了#{@attraction_name}门票订单", weight: 12 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到门票订单"
        
        @ticket_orders = all_ticket_orders
        expect(@ticket_orders.size).to be >= 1, "未找到门票订单"
      end

      return if @ticket_orders.nil? || @ticket_orders.empty?

      # 断言2: 景区正确（张家界国家森林公园） (8%)
      add_assertion "景区正确（#{@attraction_name}）", weight: 8 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景区错误。期望: #{@attraction_name}, 实际: #{order.ticket.attraction.name}"
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
      
      # 断言4: 门票游客信息正确（刘强+陈静） (7%)
      add_assertion "门票游客信息正确（刘强+陈静）", weight: 7 do
        all_passengers = @ticket_orders.flat_map { |o| o.passengers.to_a }.uniq
        expect(all_passengers.size).to eq(2),
          "门票游客数量错误。期望: 2人（刘强+陈静），实际: #{all_passengers.size}人"
        
        passenger_names = all_passengers.map(&:name).sort
        expected_names = [@liuqiang.name, @chenjing.name].sort
        expect(passenger_names).to eq(expected_names),
          "门票游客信息错误。期望: #{expected_names.join('、')}，实际: #{passenger_names.join('、')}"
      end

      # 断言5: 游玩日期正确（7天后） (8%)
      add_assertion "游玩日期正确（#{@visit_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @ticket_orders.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "游玩日期错误。期望: #{@visit_date}（7天后），实际: #{order.visit_date}"
        end
      end

      # 断言6: 创建了酒店订单 (12%)
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

      # 断言7: 酒店名称正确（张家界武陵源度假酒店） (8%)
      add_assertion "酒店名称正确（#{@hotel_name}）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel_name),
            "酒店名称错误。期望: #{@hotel_name}，实际: #{booking.hotel.name}"
        end
      end

      # 断言8: 房型正确（豪华双床房） (5%)
      add_assertion "房型正确（#{@room_type}）", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel_room.room_type).to eq(@room_type),
            "房型错误。期望: #{@room_type}，实际: #{booking.hotel_room.room_type}"
        end
      end

      # 断言9: 入住退房日期正确（2晚） (8%)
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
      
      # 断言10: 房间数和人数正确（1间房，2成人） (5%)
      add_assertion "房间数和人数正确（1间房，2成人）", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.rooms_count).to eq(1),
            "房间数错误。期望: 1间房，实际: #{booking.rooms_count}间房"
          expect(booking.adults_count).to eq(2),
            "成人数错误。期望: 2成人，实际: #{booking.adults_count}成人"
        end
      end
      
      # 断言11: 联系人信息正确（刘强或陈静） (10%)
      add_assertion "联系人信息正确（刘强或陈静）", weight: 10 do
        # 验证门票订单联系人
        @ticket_orders.each do |order|
          if order.respond_to?(:contact_name) && order.contact_name.present?
            expect(@expected_contact_names).to include(order.contact_name),
              "门票联系人姓名错误。期望: #{@expected_contact_names.join('或')}, 实际: #{order.contact_name}"
            expected_phone = @expected_contact_phones[order.contact_name]
            if expected_phone
              expect(order.contact_phone).to eq(expected_phone),
                "门票联系电话错误。期望: #{expected_phone}, 实际: #{order.contact_phone}"
            end
          elsif order.contact_phone.present?
            expect(@expected_contact_phones.values).to include(order.contact_phone),
              "门票联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{order.contact_phone}"
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
      
      # 断言12: 订单状态和价格有效 (9%)
      add_assertion "订单状态和价格有效", weight: 9 do
        @ticket_orders.each do |order|
          expect(['pending', 'paid', 'confirmed']).to include(order.status),
            "门票订单状态无效。期望: pending/paid/confirmed，实际: #{order.status}"
          expect(order.total_price).to be > 0,
            "门票订单价格无效。期望: >0，实际: #{order.total_price}"
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
      
      # 1. 创建门票订单
      ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        passenger_ids: [@liuqiang.id, @chenjing.id],  # ✅ 关联2个游客
        contact_phone: contact_passenger.phone,
        total_price: @ticket.current_price * 2,
        status: 'pending',
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
        status: 'pending',
        data_version: @data_version  # ✅ Session-scoped
      )
      
      {
        action: 'create_ticket_and_hotel_orders',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    private

    def execution_state_data
      {
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        visit_date: @visit_date&.to_s,
        attraction_name: @attraction_name,
        city_name: @city_name,
        hotel_name: @hotel_name,
        room_type: @room_type,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id,
        ticket_id: @ticket&.id,
        hotel_room_id: @hotel_room&.id,
        liuqiang_id: @liuqiang&.id,
        chenjing_id: @chenjing&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end

    def restore_from_state(state)
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @attraction_name = state['attraction_name']
      @city_name = state['city_name']
      @hotel_name = state['hotel_name']
      @room_type = state['room_type']
      @expected_contact_names = state['expected_contact_names']
      @expected_contact_phones = state['expected_contact_phones']
      
      @attraction = Attraction.find(state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find(state['hotel_id']) if state['hotel_id']
      @ticket = Ticket.find(state['ticket_id']) if state['ticket_id']
      @hotel_room = HotelRoom.find(state['hotel_room_id']) if state['hotel_room_id']
      @liuqiang = Passenger.find(state['liuqiang_id']) if state['liuqiang_id']
      @chenjing = Passenger.find(state['chenjing_id']) if state['chenjing_id']
    end
  end
end