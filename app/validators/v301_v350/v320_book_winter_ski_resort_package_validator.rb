# frozen_string_literal: true

module V301V350
  class V320BookWinterSkiResortPackageValidator < BaseValidator
    self.validator_id = 320
    self.task_id = "d4e5f6g7-8h9i-0j1k-2l3m-4n5o6p7q8r9s"
    self.title = "寒假滑雪季套餐预订（12月-2月）"
    self.description = "用户需要预订寒假期间（1月中旬）崇礼滑雪场+酒店+装备租赁套餐"
    self.timeout_seconds = 180

    def prepare
      # 寒假滑雪季：明年1月15日
      @visit_date = Date.today + 45.days
      @check_in_date = @visit_date
      @check_out_date = @visit_date + 2.days
      @resort_name = "崇礼万龙滑雪场"
      @city_name = "张家口"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: "崇礼",
        data_version: 0
      )

      # 创建滑雪场景点
      @attraction = Attraction.find_by!(
        name: @resort_name,
        city: city,
        data_version: 0
      )

      # 创建滑雪票
      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建装备租赁活动
      @ski_equipment = @attraction.attraction_activities.find_by!(
        name: "滑雪装备租赁（全套）",
        data_version: 0
      )

      # 创建滑雪场酒店
      @hotel = Hotel.find_by!(
        name: "崇礼万龙度假酒店",
        city: @city_name,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "滑雪主题大床房",
        data_version: 0
      )

      {
        visit_date: @visit_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        resort_name: @resort_name,
        city_name: @city_name,
        task_info: "用户预订寒假滑雪季套餐"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建滑雪票订单
      ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        contact_phone: '13800138000',
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建酒店订单
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
        status: 'pending',
        data_version: @data_version
      )
      hotel_booking.calculate_total_price
      hotel_booking.save!
      
      {
        action: 'create_ski_ticket_and_hotel',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了滑雪票订单", weight: 30 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @resort_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到滑雪票订单"
        
        @ticket_orders = all_ticket_orders.select { |o| o.visit_date == @visit_date }
        expect(@ticket_orders.size).to be >= 1, "未找到符合日期的滑雪票"
      end

      add_assertion "创建了滑雪场酒店订单", weight: 25 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city_id: City.find_by(name: @city_name, data_version: 0)&.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @check_in_date
        }
        expect(@hotel_bookings.size).to be >= 1, "未找到符合日期的酒店订单"
      end

      return if (@ticket_orders.nil? || @ticket_orders.empty?) && 
                (@hotel_bookings.nil? || @hotel_bookings.empty?)

      add_assertion "滑雪场正确（#{@resort_name}）", weight: 15 do
        @ticket_orders&.each do |order|
          expect(order.ticket.attraction.name).to eq(@resort_name),
            "滑雪场错误。期望: #{@resort_name}, 实际: #{order.ticket.attraction.name}"
        end
      end

      add_assertion "滑雪日期正确（寒假滑雪季：#{@visit_date}）", weight: 15 do
        @ticket_orders&.each do |order|
          expect(order.visit_date).to eq(@visit_date),
            "滑雪日期错误。期望: #{@visit_date}（寒假滑雪季），实际: #{order.visit_date}"
        end
      end

      add_assertion "酒店位置靠近滑雪场", weight: 15 do
        @hotel_bookings&.each do |booking|
          hotel_name = booking.hotel.name
          hotel_address = booking.hotel.address || ""
          ski_keywords = ['滑雪', '万龙', '崇礼']
          
          has_ski_location = ski_keywords.any? { |kw| hotel_name.include?(kw) || hotel_address.include?(kw) }
          expect(has_ski_location).to be(true),
            "酒店位置不在滑雪场附近。酒店名称: #{hotel_name}"
        end
      end
    end

    def execution_state_data
      {
        visit_date: @visit_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        resort_name: @resort_name,
        city_name: @city_name,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id
      }
    end

    def restore_from_state(state)
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @resort_name = state['resort_name']
      @city_name = state['city_name']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
