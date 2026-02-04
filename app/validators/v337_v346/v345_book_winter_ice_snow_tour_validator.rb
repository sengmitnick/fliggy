# frozen_string_literal: true

module V337V346
  class V345BookWinterIceSnowTourValidator < BaseValidator
    self.validator_id = 345
    self.task_id = "i9j0k1l2-3m4n-5o6p-7q8r-9s0t1u2v3w4x"
    self.title = "冬季冰雪游（滑雪场+温泉）"
    self.description = "用户需要预订冬季（12月-2月）哈尔滨冰雪大世界+亚布力滑雪+温泉酒店套餐"
    self.timeout_seconds = 180

    def prepare
      # 冬季冰雪季：明年1月10日
      @visit_date = Date.today + 40.days
      @check_in_date = @visit_date
      @check_out_date = @visit_date + 2.days
      @city_name = "哈尔滨"
      @ice_world_name = "哈尔滨冰雪大世界"
      @ski_resort_name = "亚布力滑雪场"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      # 创建冰雪大世界景点
      @ice_world = Attraction.find_by!(
        name: @ice_world_name,
        city: city,
        data_version: 0
      )

      @ice_ticket = Ticket.find_by!(
        attraction: @ice_world,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建亚布力滑雪场
      @ski_resort = Attraction.find_by!(
        name: @ski_resort_name,
        city: city,
        data_version: 0
      )

      @ski_ticket = Ticket.find_by!(
        attraction: @ski_resort,
        ticket_type: "adult",
        data_version: 0
      )

      # 创建温泉酒店
      @hotel = Hotel.find_by!(
        name: "哈尔滨温泉度假酒店",
        city: city,
        destination: destination,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "温泉套房",
        data_version: 0
      )

      {
        visit_date: @visit_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        city_name: @city_name,
        ice_world_name: @ice_world_name,
        ski_resort_name: @ski_resort_name,
        task_info: "用户预订冬季冰雪游套餐"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建冰雪大世界门票订单
      ice_ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ice_ticket.id,
        visit_date: @visit_date,
        quantity: 2,
        contact_phone: '13800138000',
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建亚布力滑雪票订单
      ski_ticket_order = TicketOrder.create!(
        user_id: user.id,
        ticket_id: @ski_ticket.id,
        visit_date: @visit_date + 1.day,
        quantity: 2,
        contact_phone: '13800138000',
        status: 'pending',
        data_version: @data_version
      )
      
      # 4. 创建温泉酒店订单
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
        action: 'create_ice_snow_tour_orders',
        ice_ticket_order_id: ice_ticket_order.id,
        ski_ticket_order_id: ski_ticket_order.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了冰雪景点门票订单", weight: 30 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(:ticket)
          .where(tickets: { attractions: { city_id: City.find_by(name: @city_name, data_version: 0)&.id } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_ticket_orders).not_to be_empty, "未找到门票订单"
        
        @ticket_orders = all_ticket_orders.select { |o| 
          o.visit_date >= @visit_date && o.visit_date <= @check_out_date
        }
        
        expect(@ticket_orders.size).to be >= 1, "未找到符合日期的冰雪景点门票"
      end

      add_assertion "创建了温泉酒店订单", weight: 25 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :room)
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

      add_assertion "选择了冰雪主题景点", weight: 15 do
        ice_keywords = ['冰雪', '滑雪', '冰灯', '雪雕', '冰雕']
        has_ice_theme = false
        
        @ticket_orders&.each do |order|
          attraction_name = order.ticket.attraction.name
          attraction_desc = order.ticket.attraction.description || ""
          
          if ice_keywords.any? { |kw| attraction_name.include?(kw) || attraction_desc.include?(kw) }
            has_ice_theme = true
          end
        end
        
        expect(has_ice_theme).to be(true), "未选择冰雪主题景点"
      end

      add_assertion "游玩日期正确（冬季冰雪季）", weight: 15 do
        @ticket_orders&.each do |order|
          actual_date = order.visit_date
          actual_month = actual_date.month
          
          # 允许12月-2月
          expect(actual_month).to be_in([12, 1, 2]),
            "游玩日期应在冬季冰雪季（12月-2月）。实际: #{actual_date}"
        end
      end

      add_assertion "选择了温泉特色酒店", weight: 15 do
        winter_keywords = ['温泉', '室内', '温暖', '供暖']
        has_winter_hotel = false
        
        @hotel_bookings&.each do |booking|
          hotel_name = booking.hotel.name
          hotel_desc = booking.hotel.description || ""
          hotel_amenities = booking.hotel.amenities || ""
          room_type = booking.room&.room_type || ""
          
          combined_text = "#{hotel_name} #{hotel_desc} #{hotel_amenities} #{room_type}"
          
          if winter_keywords.any? { |kw| combined_text.include?(kw) }
            has_winter_hotel = true
          end
        end
        
        expect(has_winter_hotel).to be(true), "未选择温泉或冬季特色酒店"
      end
    end

    def execution_state_data
      {
        visit_date: @visit_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        city_name: @city_name,
        ice_world_name: @ice_world_name,
        ski_resort_name: @ski_resort_name,
        ice_world_id: @ice_world&.id,
        ski_resort_id: @ski_resort&.id,
        hotel_id: @hotel&.id
      }
    end

    def restore_from_state(state)
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @city_name = state['city_name']
      @ice_world_name = state['ice_world_name']
      @ski_resort_name = state['ski_resort_name']
      @ice_world = Attraction.find_by(id: state['ice_world_id']) if state['ice_world_id']
      @ski_resort = Attraction.find_by(id: state['ski_resort_id']) if state['ski_resort_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
