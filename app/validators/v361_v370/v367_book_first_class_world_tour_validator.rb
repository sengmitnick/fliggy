# frozen_string_literal: true

# V367: 预订头等舱环球旅行+多国连线酒店验证器
#
# 功能描述：
#   用户需要预订头等舱环球旅行+多国连线酒店
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
module V361V370
  class V367BookFirstClassWorldTourValidator < BaseValidator
    self.validator_id = 367
    self.task_id = '4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f9a'
    self.title = '预订头等舱环球旅行+多国连线酒店'
    self.description = '用户需要预订头等舱环球旅行，包含多国连线酒店住宿'
    self.timeout_seconds = 180

    def prepare
      # 创建第一段航班（北京→东京）
      @flight1 = Flight.find_by!(
        flight_number: "CA925",
        departure_airport: "北京首都国际机场",
        arrival_airport: "东京成田国际机场",
        departure_city: "北京",
        arrival_city: "东京",
        data_version: 0
      )

      @flight_offer1 = FlightOffer.find_by!(
        flight: @flight1,
        cabin_class: "头等舱",
        data_version: 0
      )

      # 创建第二段航班（东京→纽约）
      @flight2 = Flight.find_by!(
        flight_number: "NH110",
        departure_airport: "东京成田国际机场",
        arrival_airport: "纽约肯尼迪国际机场",
        departure_city: "东京",
        arrival_city: "纽约",
        data_version: 0
      )

      @flight_offer2 = FlightOffer.find_by!(
        flight: @flight2,
        cabin_class: "头等舱",
        data_version: 0
      )

      # 创建东京酒店
      @hotel_tokyo = Hotel.find_by!(
        name: "东京帝国酒店",
        city: "东京",
        data_version: 0
      )

      # 创建纽约酒店
      @hotel_ny = Hotel.find_by!(
        name: "纽约华尔道夫酒店",
        city: "纽约",
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "world_traveler_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '环球旅行家'
      end

      # 设置日期
      @departure_date1 = Date.today + 7.days
      @check_in_tokyo = @departure_date1
      @check_out_tokyo = @check_in_tokyo + 3.days
      @departure_date2 = Date.today + 10.days
      @check_in_ny = @departure_date2
      @check_out_ny = @check_in_ny + 5.days

      {
        user_id: @user.id,
        user_name: @user.name,
        flight1_number: @flight1.flight_number,
        flight2_number: @flight2.flight_number,
        hotel_tokyo: @hotel_tokyo.name,
        hotel_ny: @hotel_ny.name,
        departure_date1: @departure_date1.to_s,
        departure_date2: @departure_date2.to_s,
        traveler_count: 2,
        cabin_class: "头等舱",
        service_type: "环球旅行+多国连线"
      }
    end

    def verify
      # 断言1: 创建了至少2段航班订单（40分）
      add_assertion "创建了至少2段航班订单", weight: 40 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { flight_number: [@flight1.flight_number, @flight2.flight_number] })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_bookings.size).to be >= 2, "航班订单数量不足。期望: 至少2段, 实际: #{all_bookings.size}段"
        @flight_bookings = all_bookings
      end

      return if @flight_bookings.nil? || @flight_bookings.empty?

      # 断言2: 所有航班舱位为头等舱（20分）
      add_assertion "所有航班舱位为头等舱", weight: 20 do
        @flight_bookings.each do |booking|
          expect(booking.cabin_class).to eq("头等舱"),
            "舱位等级错误。期望: 头等舱, 实际: #{booking.cabin_class}"
        end
      end

      # 断言3: 创建了至少2个酒店订单（20分）
      add_assertion "创建了至少2个酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { name: [@hotel_tokyo.name, @hotel_ny.name] })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_hotel_bookings.size).to be >= 2, "酒店订单数量不足。期望: 至少2个, 实际: #{all_hotel_bookings.size}个"
        @hotel_bookings = all_hotel_bookings
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言4: 所有酒店星级为五星（20分）
      add_assertion "所有酒店星级为五星级", weight: 20 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.star_rating).to eq("五星级"),
            "酒店星级错误。期望: 五星级, 实际: #{booking.hotel.star_rating}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、预订多段头等舱航班、预订多国连线酒店"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        flight1_id: @flight1&.id,
        flight2_id: @flight2&.id,
        hotel_tokyo_id: @hotel_tokyo&.id,
        hotel_ny_id: @hotel_ny&.id,
        departure_date1: @departure_date1&.to_s,
        departure_date2: @departure_date2&.to_s
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @flight1 = Flight.find_by(id: state['flight1_id']) if state['flight1_id']
      @flight2 = Flight.find_by(id: state['flight2_id']) if state['flight2_id']
      @hotel_tokyo = Hotel.find_by(id: state['hotel_tokyo_id']) if state['hotel_tokyo_id']
      @hotel_ny = Hotel.find_by(id: state['hotel_ny_id']) if state['hotel_ny_id']
      @departure_date1 = Date.parse(state['departure_date1']) if state['departure_date1']
      @departure_date2 = Date.parse(state['departure_date2']) if state['departure_date2']
    end
  end
end
