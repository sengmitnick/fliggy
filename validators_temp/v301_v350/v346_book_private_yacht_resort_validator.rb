# frozen_string_literal: true

# V366: 预订私人游艇+海岛度假村+管家服务验证器
#
# 功能描述：
#   用户需要预订私人游艇+海岛度假村+管家服务
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
  class V346BookPrivateYachtResortValidator < BaseValidator
    self.validator_id = 346
    self.task_id = '3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e8f'
    self.title = '预订私人游艇+海岛度假村+管家服务'
    self.description = '用户需要预订私人游艇出海，包含海岛度假村住宿和私人管家服务'
    self.timeout_seconds = 180

    def prepare
      # 创建游轮产品（代替游艇）
      @cruise_line = CruiseLine.find_by!(
        name: "海上奢华游艇服务",
        data_version: 0
      )

      @cruise_ship = CruiseShip.find_by!(
        name: "海洋之星私人游艇",
        cruise_line: @cruise_line,
        data_version: 0
      )

      # 创建游艇航次
      @cruise_sailing = CruiseSailing.find_by!(
        cruise_ship: @cruise_ship,
        departure_date: Date.today + 10.days,
        data_version: 0
      )

      # 创建度假村酒店
      @hotel = Hotel.find_by!(
        name: "三亚亚特兰蒂斯海岛度假村",
        city: "三亚",
        data_version: 0
      )

      # 创建豪华套房
      @hotel_room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: "海景别墅套房",
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "luxury_traveler_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '奢华旅行者'
      end

      # 设置日期
      @sailing_date = Date.today + 10.days
      @check_in_date = @sailing_date + 2.days
      @check_out_date = @check_in_date + 3.days

      {
        user_id: @user.id,
        user_name: @user.name,
        yacht_name: @cruise_ship.name,
        sailing_date: @sailing_date.to_s,
        hotel_name: @hotel.name,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        traveler_count: 2,
        service_type: "私人游艇+海岛度假村+管家服务"
      }
    end

    def verify
      # 断言1: 创建了游艇订单（35分）
      add_assertion "创建了私人游艇订单", weight: 35 do
        all_orders = CruiseOrder
          .joins(:cruise_sailing)
          .includes(cruise_sailing: :cruise_ship)
          .where(cruise_sailings: { cruise_ships: { name: @cruise_ship.name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到私人游艇订单"
        @cruise_orders = all_orders
      end

      return if @cruise_orders.nil? || @cruise_orders.empty?

      # 断言2: 游艇正确（海洋之星私人游艇）（15分）
      add_assertion "游艇正确（#{@cruise_ship.name}）", weight: 15 do
        @cruise_orders.each do |order|
          expect(order.cruise_sailing.cruise_ship.name).to eq(@cruise_ship.name),
            "游艇错误。期望: #{@cruise_ship.name}, 实际: #{order.cruise_sailing.cruise_ship.name}"
        end
      end

      # 断言3: 出航日期正确（10分）
      add_assertion "出航日期正确（#{@sailing_date}）", weight: 10 do
        @cruise_orders.each do |order|
          expect(order.cruise_sailing.departure_date).to eq(@sailing_date),
            "出航日期错误。期望: #{@sailing_date}（10天后）, 实际: #{order.cruise_sailing.departure_date}"
        end
      end

      # 断言4: 创建了度假村酒店订单（20分）
      add_assertion "创建了海岛度假村订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_hotel_bookings).not_to be_empty, "未找到度假村订单"
        @hotel_bookings = all_hotel_bookings
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言5: 酒店类型为度假村（10分）
      add_assertion "酒店类型为度假村", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.type).to eq("度假村"),
            "酒店类型错误。期望: 度假村, 实际: #{booking.hotel.type}"
        end
      end

      # 断言6: 酒店星级为五星（10分）
      add_assertion "酒店星级为五星级", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.star_rating).to eq("五星级"),
            "酒店星级错误。期望: 五星级, 实际: #{booking.hotel.star_rating}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、预订私人游艇（#{@cruise_ship.name}）、预订海岛度假村（#{@hotel.name}）"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        cruise_ship_id: @cruise_ship&.id,
        cruise_sailing_id: @cruise_sailing&.id,
        hotel_id: @hotel&.id,
        sailing_date: @sailing_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @cruise_ship = CruiseShip.find_by(id: state['cruise_ship_id']) if state['cruise_ship_id']
      @cruise_sailing = CruiseSailing.find_by(id: state['cruise_sailing_id']) if state['cruise_sailing_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      @sailing_date = Date.parse(state['sailing_date']) if state['sailing_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
    end
  end
end
