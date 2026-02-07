# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例198: 预订景区附近酒店+景区门票
#
# 任务描述:
#   预订景区附近酒店+景区门票
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 创建了门票订单 (30%)
#   - 酒店在景区所在城市 (15%)
#   - 游玩日期合理 (15%)
#   - 景点正确 (10%)
module V151V200
  class V198BookHotelNearAttractionAndTicketsValidator < BaseValidator
    self.validator_id = 'v198_book_hotel_near_attraction_and_tickets_validator'
    self.task_id = 'f5b7ea8b-d7b9-4ea6-9563-805862ebaa67'
    self.title = '预订景区附近酒店+景区门票'
    self.description = '预订景区附近酒店+景区门票'
    self.timeout_seconds = 300
    
    def prepare
      @attraction_name = '北京欢乐谷'
      @city = '北京'
      @visit_date = Date.tomorrow + 2.days
      
      # 查找景点
      @attraction = Attraction.find_by(name: @attraction_name, data_version: 0)
      expect(@attraction).not_to be_nil, "数据包缺少景点：#{@attraction_name}"
      
      # 查找景点门票
      @available_tickets = Ticket
        .where(attraction_id: @attraction.id, data_version: 0)
        .to_a
      
      expect(@available_tickets).not_to be_empty,
        "数据包缺少#{@attraction_name}的门票"
      
      # 查找景区附近酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@city}的酒店"
      
      {
        task: "请预订#{@visit_date.strftime('%m月%d日')}#{@attraction_name}的门票，并预订#{@city}的酒店",
        attraction: @attraction_name,
        city: @city,
        visit_date: @visit_date.strftime('%Y-%m-%d'),
        hint: "预订景区门票和附近酒店"
      }
    end
    
    def verify
      # 断言1: 创建了酒店订单 (30%)
      add_assertion "创建了酒店订单", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@city}）"
      end
      
      # 断言2: 创建了门票订单 (30%)
      add_assertion "创建了门票订单", weight: 30 do
        @ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(tickets: { attractions: { name: @attraction_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@ticket_orders).not_to be_empty, "未找到门票订单（#{@attraction_name}）"
      end
      
      return if @hotel_booking.nil? || @ticket_orders.empty?
      
      # 断言3: 酒店在景区所在城市 (15%)
      add_assertion "酒店在景区所在城市（#{@city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@city)
      end
      
      # 断言4: 游玩日期合理 (15%)
      add_assertion "游玩日期合理", weight: 15 do
        ticket_order = @ticket_orders.first
        visit_date = ticket_order.visit_date
        checkin_date = @hotel_booking.check_in_date
        
        # 入住日期应为游玩前一天或当天
        expect([visit_date - 1.day, visit_date]).to include(checkin_date),
          "入住日期不合理。游玩日期: #{visit_date}, 入住日期: #{checkin_date}（应为游玩前一天或当天）"
      end
      
      # 断言5: 景点正确 (10%)
      add_assertion "景点正确（#{@attraction_name}）", weight: 10 do
        ticket_order = @ticket_orders.first
        attraction = ticket_order.ticket.attraction
        expect(attraction.name).to eq(@attraction_name)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建门票订单
      ticket = @available_tickets.first
      TicketOrder.create!(
        user: user,
        ticket: ticket,
        contact_phone: '13800138000',
        visit_date: @visit_date,
        quantity: 1,
        total_price: ticket.current_price,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.min_by(&:price)
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      # 入住前一天
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @visit_date - 1.day,
        check_out_date: @visit_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price * 2,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        attraction_name: @attraction_name,
        city: @city,
        visit_date: @visit_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @attraction_name = data['attraction_name']
      @city = data['city']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
    end
  end
end
