# frozen_string_literal: true

module V301V350
  class V318BookNationalDayAttractionHotelPackageValidator < BaseValidator
    self.validator_id = 'v318_book_national_day_attraction_hotel_package_validator'
    self.task_id = "2fa37623-24e7-46f7-a054-b2c98c7c7227"
    self.title = "预订7天后张家界国家森林公园门票+张家界武陵源度假酒店（2晚，1间房，2人）"
    self.description = "用户需要预订7天后的张家界国家森林公园成人门票（2张）和张家界武陵源度假酒店豪华双床房（入住2晚）"
    self.timeout_seconds = 180

    def prepare
      # 7天后入住，住2晚
      @check_in_date = Date.today + 7.days
      @check_out_date = @check_in_date + 2.days
      @visit_date = @check_in_date
      @attraction_name = "张家界国家森林公园"
      @city_name = "张家界"
      
      # 创建城市和目的地
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      # 创建景区
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        city: @city_name,
        data_version: 0
      )

      # 创建门票
      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建酒店
      @hotel = Hotel.find_by!(
        name: "张家界武陵源度假酒店",
        city: @city_name,
        data_version: 0
      )

      # 创建房型
      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "豪华双床房",
        data_version: 0
      )

      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（7天后）的张家界国家森林公园成人门票2张，以及张家界武陵源度假酒店豪华双床房（入住#{@check_in_date.strftime('%m月%d日')}至#{@check_out_date.strftime('%m月%d日')}，共2晚）。",
        requirements: {
          attraction_name: @attraction_name,
          city_name: @city_name,
          visit_date: @visit_date,
          check_in_date: @check_in_date,
          check_out_date: @check_out_date,
          ticket_quantity: 2,
          nights: 2,
          hotel_name: '张家界武陵源度假酒店',
          room_type: '豪华双床房'
        },
        hint: "景区门票和酒店可以分别预订，注意日期要匹配。"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建门票订单
      ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        contact_phone: '13800138000',
        total_price: @ticket.current_price * 2,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建酒店订单
      nights = (@check_out_date - @check_in_date).to_i
      base_price = @hotel_room.price * nights * 1
      hotel_booking = HotelBooking.create!(
        hotel_id: @hotel.id,
        hotel_room_id: @hotel_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: '张三',
        guest_phone: '13800138000',
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        payment_method: '花呗',
        total_price: base_price,
        status: 'pending',
        data_version: @data_version
      )
      
      {
        action: 'create_ticket_and_hotel_orders',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了门票订单", weight: 25 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到门票订单"
        
        @ticket_orders = all_ticket_orders.select { |o| o.visit_date == @visit_date }
        expect(@ticket_orders.size).to be >= 1, "未找到符合日期的门票订单"
      end

      add_assertion "创建了酒店订单", weight: 25 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @check_in_date && b.check_out_date == @check_out_date
        }
        expect(@hotel_bookings.size).to be >= 1, "未找到符合日期的酒店订单"
      end

      return if (@ticket_orders.nil? || @ticket_orders.empty?) && 
                (@hotel_bookings.nil? || @hotel_bookings.empty?)

      add_assertion "景区正确（#{@attraction_name}）", weight: 15 do
        @ticket_orders&.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景区错误。期望: #{@attraction_name}, 实际: #{order.ticket.attraction.name}"
        end
      end

      add_assertion "游玩日期正确（7天后：#{@visit_date}）", weight: 15 do
        @ticket_orders&.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "游玩日期错误。期望: #{@visit_date}（7天后），实际: #{order.visit_date}"
        end
      end

      add_assertion "酒店入住退房日期正确（7天后入住，住2晚：#{@check_in_date}至#{@check_out_date}）", weight: 15 do
        @hotel_bookings&.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}, 实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}, 实际: #{booking.check_out_date}"
        end
      end
      
      add_assertion "房间数和人数正确（1间房，2成人，0儿童）", weight: 10 do
        @hotel_bookings&.each do |booking|
          expect(booking.rooms_count).to eq(1),
            "房间数错误。期望: 1间房，实际: #{booking.rooms_count}间房"
          expect(booking.adults_count).to eq(2),
            "成人数错误。期望: 2成人，实际: #{booking.adults_count}成人"
          expect(booking.children_count).to eq(0),
            "儿童数错误。期望: 0儿童，实际: #{booking.children_count}儿童"
        end
      end
    end

    def execution_state_data
      {
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        visit_date: @visit_date&.to_s,
        attraction_name: @attraction_name,
        city_name: @city_name,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id
      }
    end

    def restore_from_state(state)
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @attraction_name = state['attraction_name']
      @city_name = state['city_name']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
