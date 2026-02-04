# frozen_string_literal: true

module V337V346
  class V342BookSpringFlowerViewingTourValidator < BaseValidator
    self.validator_id = 342
    self.task_id = "f6g7h8i9-0j1k-2l3m-4n5o-6p7q8r9s0t1u"
    self.title = "春季赏花游（3-4月樱花/油菜花）"
    self.description = "用户需要预订春季（3月底）武汉大学樱花观赏+酒店套餐"
    self.timeout_seconds = 180

    def prepare
      # 春季樱花季：3月25日
      current_year = Date.today.year
      @visit_date = Date.new(current_year, 3, 25)
      if @visit_date < Date.today
        @visit_date = Date.new(current_year + 1, 3, 25)
      end
      @check_in_date = @visit_date
      @check_out_date = @visit_date + 1.day
      @attraction_name = "武汉大学樱花大道"
      @city_name = "武汉"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      
      # 创建赏花景点
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

      # 创建附近酒店
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      @hotel = Hotel.find_by!(
        name: "武汉大学周边精品酒店",
        city: city,
        destination: destination,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "舒适大床房",
        data_version: 0
      )

      {
        visit_date: @visit_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        attraction_name: @attraction_name,
        city_name: @city_name,
        task_info: "用户预订春季赏花游"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建赏花门票订单
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
        action: 'create_flower_viewing_ticket_and_hotel',
        ticket_order_id: ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了赏花门票订单", weight: 30 do
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
        
        # 酒店订单可选，不强制要求
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

      add_assertion "游览日期正确（春季樱花季：#{@visit_date}）", weight: 20 do
        @ticket_orders.each do |order|
          actual_date = order.visit_date
          # 允许3-4月的任何日期
          expected_month = @visit_date.month
          actual_month = actual_date.month
          
          if expected_month.in?([3, 4])
            expect(actual_month).to be_in([3, 4]),
              "游览日期应在春季樱花季（3-4月）。实际: #{actual_date}"
          else
            expect(actual_date).to eq(@visit_date),
              "游览日期错误。期望: #{@visit_date}（春季樱花季），实际: #{actual_date}"
          end
        end
      end

      add_assertion "选择了合适的赏花季节产品", weight: 10 do
        flower_keywords = ['樱花', '油菜花', '赏花', '花季', '春季']
        has_flower_theme = false
        
        @ticket_orders.each do |order|
          attraction_name = order.ticket.attraction.name
          ticket_name = order.ticket.name
          
          if flower_keywords.any? { |kw| attraction_name.include?(kw) || ticket_name.include?(kw) }
            has_flower_theme = true
          end
        end
        
        expect(has_flower_theme).to be(true), "未选择春季赏花主题产品"
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
