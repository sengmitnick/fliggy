# frozen_string_literal: true

# V365: 预订企业包机+五星酒店+豪华车队接送验证器
#
# 功能描述：
#   用户需要预订企业包机+五星级酒店+豪华车队接送服务
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
  class V345BookCorporateCharterFlightValidator < BaseValidator
    self.validator_id = 345
    self.task_id = '2b3c4d5e-6f7a-8b9c-0d1e-2f3a4b5c6d7e'
    self.title = '预订企业包机+五星酒店+豪华车队接送'
    self.description = '用户需要预订企业包机服务，包含五星级酒店住宿和豪华车队接送'
    self.timeout_seconds = 180

    def prepare
      # 创建航班（包机服务）
      @flight = Flight.find_by!(
        flight_number: "CZ9001",
        departure_airport: "北京首都国际机场",
        arrival_airport: "三亚凤凰国际机场",
        departure_city: "北京",
        destination_city: "三亚",
        data_version: 0
      )

      # 创建航班报价（包机报价）
      @flight_offer = FlightOffer.find_by!(
        flight: @flight,
        cabin_class: "商务舱",
        data_version: 0
      )

      # 创建五星级酒店
      @hotel = Hotel.find_by!(
        name: "三亚海棠湾万达瑞华酒店",
        city: "三亚",
        data_version: 0
      )

      # 创建豪华套房
      @hotel_room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: "行政套房",
        data_version: 0
      )

      # 创建租车服务（豪华车队）
      @car = Car.find_by!(
        name: "奔驰S级轿车车队",
        brand: "奔驰",
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "corporate_vip_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '企业VIP客户'
      end

      # 设置日期
      @departure_date = Date.today + 5.days
      @check_in_date = @departure_date
      @check_out_date = @check_in_date + 3.days

      {
        user_id: @user.id,
        user_name: @user.name,
        flight_number: @flight.flight_number,
        departure_city: @flight.departure_city,
        arrival_city: @flight.arrival_city,
        departure_date: @departure_date.to_s,
        hotel_name: @hotel.name,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        car_name: @car.name,
        traveler_count: 10,
        service_type: "企业包机+五星酒店+豪华车队"
      }
    end

    def verify
      # 断言1: 创建了包机订单（30分）
      add_assertion "创建了包机订单", weight: 30 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { flight_number: @flight.flight_number })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_bookings).not_to be_empty, "未找到包机订单"
        @flight_bookings = all_bookings
      end

      return if @flight_bookings.nil? || @flight_bookings.empty?

      # 断言2: 航班正确（CZ9001）（10分）
      add_assertion "航班正确（#{@flight.flight_number}）", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.flight.flight_number).to eq(@flight.flight_number),
            "航班错误。期望: #{@flight.flight_number}, 实际: #{booking.flight.flight_number}"
        end
      end

      # 断言3: 舱位等级为商务舱（10分）
      add_assertion "舱位等级为商务舱", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.cabin_class).to eq("商务舱"),
            "舱位等级错误。期望: 商务舱, 实际: #{booking.cabin_class}"
        end
      end

      # 断言4: 创建了五星级酒店订单（20分）
      add_assertion "创建了五星级酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_hotel_bookings).not_to be_empty, "未找到五星级酒店订单"
        @hotel_bookings = all_hotel_bookings
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言5: 酒店星级为五星（10分）
      add_assertion "酒店星级为五星级", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.star_rating).to eq("五星级"),
            "酒店星级错误。期望: 五星级, 实际: #{booking.hotel.star_rating}"
        end
      end

      # 断言6: 创建了豪华租车订单（15分）
      add_assertion "创建了豪华租车订单", weight: 15 do
        all_car_orders = CarOrder
          .joins(:car)
          .includes(:car)
          .where(cars: { name: @car.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_car_orders).not_to be_empty, "未找到豪华租车订单"
        @car_orders = all_car_orders
      end

      # 断言7: 租车品牌为奔驰（5分）
      add_assertion "租车品牌为奔驰", weight: 5 do
        @car_orders.each do |order|
          expect(order.car.brand).to eq("奔驰"),
            "租车品牌错误。期望: 奔驰, 实际: #{order.car.brand}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、预订包机航班（#{@flight.flight_number}）、预订五星酒店（#{@hotel.name}）、预订豪华租车（#{@car.name}）"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        flight_id: @flight&.id,
        hotel_id: @hotel&.id,
        car_id: @car&.id,
        departure_date: @departure_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @flight = Flight.find_by(id: state['flight_id']) if state['flight_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      @car = Car.find_by(id: state['car_id']) if state['car_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
    end
  end
end
