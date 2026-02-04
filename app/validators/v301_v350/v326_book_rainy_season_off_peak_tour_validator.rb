# frozen_string_literal: true

module V301V350
  class V326BookRainySeasonOffPeakTourValidator < BaseValidator
    self.validator_id = 326
    self.task_id = "j0k1l2m3-4n5o-6p7q-8r9s-0t1u2v3w4x5y"
    self.title = "雨季错峰游（淡季优惠套餐）"
    self.description = "用户需要预订雨季（6月）桂林山水游淡季优惠套餐，价格实惠"
    self.timeout_seconds = 180

    def prepare
      # 雨季淡季：6月15日
      current_year = Date.today.year
      @departure_date = Date.new(current_year, 6, 15)
      if @departure_date < Date.today
        @departure_date = Date.new(current_year + 1, 6, 15)
      end
      @return_date = @departure_date + 3.days
      @visit_date = @departure_date + 1.day
      @city_name = "桂林"
      @attraction_name = "漓江风景区"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      # 创建景点
      @attraction = Attraction.find_by!(
        name: @attraction_name,
        city: city,
        data_version: 0
      )

      # 创建淡季优惠票
      @ticket = Ticket.find_by!(
        attraction: @attraction,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建漓江竹筏体验
      @bamboo_raft = @attraction.attraction_activities.find_by!(
        name: "漓江竹筏漂流",
        data_version: 0
      )

      # 创建淡季优惠酒店
      @hotel = Hotel.find_by!(
        name: "桂林漓江边经济型酒店",
        city: city,
        destination: destination,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "经济双床房",
        data_version: 0
      )

      {
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        visit_date: @visit_date.to_s,
        city_name: @city_name,
        attraction_name: @attraction_name,
        task_info: "用户预订雨季淡季优惠套餐"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建漓江门票订单
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
        check_in_date: @departure_date,
        check_out_date: @return_date,
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
        action: 'create_offpeak_tour_ticket_and_hotel',
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
        
        @ticket_orders = all_ticket_orders.select { |o| 
          o.visit_date >= @visit_date && o.visit_date <= @return_date
        }
        
        expect(@ticket_orders.size).to be >= 1, "未找到符合日期的门票"
      end

      add_assertion "创建了酒店订单", weight: 25 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :room)
          .where(hotels: { city_id: City.find_by(name: @city_name, data_version: 0)&.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @departure_date
        }
        
        expect(@hotel_bookings.size).to be >= 1, "未找到符合日期的酒店订单"
      end

      return if (@ticket_orders.nil? || @ticket_orders.empty?) && 
                (@hotel_bookings.nil? || @hotel_bookings.empty?)

      add_assertion "景点正确（#{@attraction_name}）", weight: 15 do
        @ticket_orders&.each do |order|
          expect(order.ticket.attraction.name).to eq(@attraction_name),
            "景点错误。期望: #{@attraction_name}, 实际: #{order.ticket.attraction.name}"
        end
      end

      add_assertion "预订时间在淡季（雨季6月）", weight: 10 do
        @ticket_orders&.each do |order|
          actual_month = order.visit_date.month
          # 雨季通常是5-6月或6-7月，这里以6月为主
          expect(actual_month).to be_in([5, 6, 7]),
            "预订时间应在雨季淡季（5-7月）。实际: #{order.visit_date}"
        end
      end

      add_assertion "选择了经济实惠的产品", weight: 20 do
        budget_keywords = ['淡季', '优惠', '特惠', '经济', '实惠', '性价比']
        has_budget_option = false
        
        # 检查门票
        @ticket_orders&.each do |order|
          ticket_name = order.ticket.name
          ticket_desc = order.ticket.description || ""
          
          if budget_keywords.any? { |kw| ticket_name.include?(kw) || ticket_desc.include?(kw) }
            has_budget_option = true
          end
          
          # 检查价格是否较低（低于300）
          if order.ticket.price < 300
            has_budget_option = true
          end
        end
        
        # 检查酒店
        @hotel_bookings&.each do |booking|
          hotel_name = booking.hotel.name
          hotel_desc = booking.hotel.description || ""
          
          if budget_keywords.any? { |kw| hotel_name.include?(kw) || hotel_desc.include?(kw) }
            has_budget_option = true
          end
          
          # 检查价格是否较低（低于400）
          if booking.hotel.price < 400
            has_budget_option = true
          end
        end
        
        expect(has_budget_option).to be(true), "未选择淡季优惠产品"
      end
    end

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s,
        visit_date: @visit_date&.to_s,
        city_name: @city_name,
        attraction_name: @attraction_name,
        attraction_id: @attraction&.id,
        hotel_id: @hotel&.id
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @return_date = Date.parse(state['return_date']) if state['return_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @city_name = state['city_name']
      @attraction_name = state['attraction_name']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
