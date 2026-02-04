# frozen_string_literal: true

# V369: 预订明星同款行程（网红酒店+打卡地）验证器
#
# 功能描述：
#   用户需要预订明星同款行程，包含网红酒店和热门打卡地
#
# API端点使用说明：
#   # 获取任务列表
#   GET /api/tasks
#   
#   # 创建执行（开始任务）
#   POST /api/tasks/:task_id/start
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V301V350
  class V349BookCelebrityRouteValidator < BaseValidator
    self.validator_id = 349
    self.task_id = '6f7a8b9c-0d1e-2f3a-4b5c-6d7e8f9a0b1c'
    self.title = '预订明星同款行程（网红酒店+打卡地）'
    self.description = '用户需要预订明星同款行程，包含网红酒店住宿和热门打卡地游览'
    self.timeout_seconds = 180

    def prepare
      # 创建网红酒店
      @hotel = Hotel.find_by!(
        name: "上海素凯泰酒店",
        city: "上海",
        data_version: 0
      )

      # 创建网红房型
      @hotel_room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: "设计师套房",
        data_version: 0
      )

      # 创建打卡景点1
      @attraction1 = Attraction.find_by!(
        name: "外滩观景台",
        city: "上海",
        data_version: 0
      )

      # 创建打卡景点2
      @attraction2 = Attraction.find_by!(
        name: "武康路网红街",
        city: "上海",
        data_version: 0
      )

      # 创建景点门票1
      @ticket1 = Ticket.find_by!(
        attraction: @attraction1,
        ticket_type: "普通票",
        data_version: 0
      )

      # 创建景点门票2
      @ticket2 = Ticket.find_by!(
        attraction: @attraction2,
        ticket_type: "普通票",
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "celebrity_fan_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '明星粉丝'
      end

      # 设置日期
      @check_in_date = Date.today + 5.days
      @check_out_date = @check_in_date + 2.days
      @visit_date = @check_in_date + 1.day

      {
        user_id: @user.id,
        user_name: @user.name,
        hotel_name: @hotel.name,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        attraction1_name: @attraction1.name,
        attraction2_name: @attraction2.name,
        visit_date: @visit_date.to_s,
        traveler_count: 2,
        service_type: "明星同款行程"
      }
    end

    def verify
      # 断言1: 创建了网红酒店订单（30分）
      add_assertion "创建了网红酒店订单", weight: 30 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_hotel_bookings).not_to be_empty, "未找到网红酒店订单"
        @hotel_bookings = all_hotel_bookings
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言2: 酒店正确（上海素凯泰酒店）（15分）
      add_assertion "酒店正确（#{@hotel.name}）", weight: 15 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel.name),
            "酒店错误。期望: #{@hotel.name}, 实际: #{booking.hotel.name}"
        end
      end

      # 断言3: 入住日期正确（10分）
      add_assertion "入住日期正确（#{@check_in_date}）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}（5天后）, 实际: #{booking.check_in_date}"
        end
      end

      # 断言4: 创建了至少1个打卡景点订单（25分）
      add_assertion "创建了至少1个打卡景点订单", weight: 25 do
        all_ticket_orders = TicketOrder
          .joins(ticket: :attraction)
          .includes(ticket: :attraction)
          .where(tickets: { attractions: { name: [@attraction1.name, @attraction2.name] } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_ticket_orders).not_to be_empty, "未找到打卡景点订单"
        @ticket_orders = all_ticket_orders
      end

      return if @ticket_orders.nil? || @ticket_orders.empty?

      # 断言5: 景点在上海（10分）
      add_assertion "景点在上海", weight: 10 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.city).to eq("上海"),
            "景点城市错误。期望: 上海, 实际: #{order.ticket.attraction.city}"
        end
      end

      # 断言6: 景点评分高（至少4.5分）（10分）
      add_assertion "景点评分高（至少4.5分）", weight: 10 do
        @ticket_orders.each do |order|
          expect(order.ticket.attraction.rating).to be >= 4.5,
            "景点评分偏低。期望: 至少4.5分, 实际: #{order.ticket.attraction.rating}分"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、预订网红酒店（#{@hotel.name}）、预订打卡景点（#{@attraction1.name}、#{@attraction2.name}）"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        hotel_id: @hotel&.id,
        attraction1_id: @attraction1&.id,
        attraction2_id: @attraction2&.id,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        visit_date: @visit_date&.to_s
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      @attraction1 = Attraction.find_by(id: state['attraction1_id']) if state['attraction1_id']
      @attraction2 = Attraction.find_by(id: state['attraction2_id']) if state['attraction2_id']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
    end
  end
end
