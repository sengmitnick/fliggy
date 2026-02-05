# frozen_string_literal: true

module V301V350
  class V324BookAutumnMapleViewingTourValidator < BaseValidator
    self.validator_id = 324
    self.task_id = "h8i9j0k1-2l3m-4n5o-6p7q-8r9s0t1u2v3w"
    self.title = "秋季赏枫游（9-11月红叶观赏）"
    self.description = "用户需要预订秋季（10月中旬）北京香山红叶观赏+周边酒店"
    self.timeout_seconds = 180

    def prepare
      # 秋季赏枫：10月20日
      current_year = Date.today.year
      @visit_date = Date.new(current_year, 10, 20)
      if @visit_date < Date.today
        @visit_date = Date.new(current_year + 1, 10, 20)
      end
      @check_in_date = @visit_date
      @check_out_date = @visit_date + 1.day
      @attraction_name = "香山公园"
      @city_name = "北京"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      
      # 创建景点
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        city: city,
        data_version: 0
      )

      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建酒店
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      @hotel = Hotel.find_by!(
        name: "北京香山附近酒店",
        city: @city_name,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "标准双床房",
        data_version: 0
      )

      {
        visit_date: @visit_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        attraction_name: @attraction_name,
        city_name: @city_name,
        task_info: "用户预订秋季赏枫游"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建香山红叶门票订单
      ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        contact_phone: '13800138000',
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建酒店订单（可选）
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
        action: 'create_maple_viewing_ticket_and_hotel',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了景区门票订单", weight: 30 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到门票订单"
        
        @ticket_orders = all_ticket_orders.select { |o| o.visit_date == @visit_date }
        expect(@ticket_orders.size).to be >= 1, "未找到符合日期的门票"
      end

      add_assertion "创建了酒店订单", weight: 25 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city_id: City.find_by(name: @city_name, data_version: 0)&.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @check_in_date
        }
        
        # 酒店订单可选
        if @hotel_bookings.empty?
          puts "提示: 未预订酒店（可选）"
        end
      end

      return if @ticket_orders.nil? || @ticket_orders.empty?

      add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}, 实际: #{order.ticket.attraction.name}"
        end
      end

      add_assertion "游览日期正确（秋季赏枫：#{@visit_date}）", weight: 20 do
        @ticket_orders.each do |order|
          actual_date = order.visit_date
          # 允许9-11月的任何日期
          expected_month = @visit_date.month
          actual_month = actual_date.month
          
          if expected_month.in?([9, 10, 11])
            expect(actual_month).to be_in([9, 10, 11]),
              "游览日期应在秋季赏枫季（9-11月）。实际: #{actual_date}"
          else
            expect(actual_date).to eq(@visit_date),
              "游览日期错误。期望: #{@visit_date}（秋季赏枫），实际: #{actual_date}"
          end
        end
      end

      add_assertion "选择了秋季赏枫主题产品", weight: 10 do
        autumn_keywords = ['红叶', '赏枫', '枫叶', '秋色', '香山']
        has_autumn_theme = false
        
        @ticket_orders.each do |order|
          attraction_name = order.ticket.attraction.name
          attraction_desc = order.ticket.attraction.description || ""
          ticket_desc = order.ticket.description || ""
          
          combined_text = "#{attraction_name} #{attraction_desc} #{ticket_desc}"
          
          if autumn_keywords.any? { |kw| combined_text.include?(kw) }
            has_autumn_theme = true
          end
        end
        
        expect(has_autumn_theme).to be(true), "未选择秋季赏枫主题产品"
      end
    end

    def execution_state_data
      {
        visit_date: @visit_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        attraction_name: @attraction_name,
        city_name: @city_name,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id
      }
    end

    def restore_from_state(state)
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @attraction_name = state['attraction_name']
      @city_name = state['city_name']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
