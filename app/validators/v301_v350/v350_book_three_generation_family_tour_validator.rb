# frozen_string_literal: true

# V370: 预订3代同堂家庭游（老中青3代6人）验证器
#
# 功能描述：
#   用户需要预订3代同堂家庭游，包含老中青3代共6人的行程
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
  class V350BookThreeGenerationFamilyTourValidator < BaseValidator
    self.validator_id = 350
    self.task_id = '7a8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d'
    self.title = '预订3代同堂家庭游（老中青3代6人）'
    self.description = '用户需要预订适合3代同堂家庭出游的行程，包含老人、成人和儿童共6人'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "全家欢乐游旅行社",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "苏州园林",
        data_version: 0
      )

      # 创建跟团游产品（家庭游）
      @tour_product = TourGroupProduct.find_by!(
        name: "苏州园林+古镇亲子家庭4日游",
        destination: @destination.name,
        data_version: 0
      )

      # 创建测试用户（家庭代表）
      @user = User.find_by!(
        email: "family_traveler_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '家庭组织者'
      end

      # 创建6位家庭成员
      @travelers = []
      [
        { name: "张爷爷", age: 70, id_type: "身份证" },
        { name: "张奶奶", age: 68, id_type: "身份证" },
        { name: "张先生", age: 40, id_type: "身份证" },
        { name: "李女士", age: 38, id_type: "身份证" },
        { name: "张小明", age: 10, id_type: "身份证" },
        { name: "张小红", age: 8, id_type: "身份证" }
      ].each do |traveler_info|
        traveler = Passenger.find_by!(
          name: traveler_info[:name],
          user: @user,
          data_version: @data_version
        )
        @travelers << traveler
      end

      # 设置出发日期
      @departure_date = Date.today + 10.days

      {
        user_id: @user.id,
        user_name: @user.name,
        destination: @destination.name,
        product_name: @tour_product.name,
        departure_date: @departure_date.to_s,
        duration: @tour_product.duration,
        traveler_count: 6,
        price: @tour_product.price,
        travelers: @travelers.map(&:name),
        service_type: "3代同堂家庭游"
      }
    end

    def verify
      # 断言1: 创建了家庭游订单（25分）
      add_assertion "创建了家庭游订单", weight: 25 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_bookings).not_to be_empty, "未找到家庭游订单"
        @bookings = all_bookings
      end

      return if @bookings.nil? || @bookings.empty?

      # 断言2: 产品正确（苏州园林+古镇亲子家庭4日游）（15分）
      add_assertion "产品正确（#{@tour_product.name}）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.tour_group_product.name).to eq(@tour_product.name),
            "产品错误。期望: #{@tour_product.name}, 实际: #{booking.tour_group_product.name}"
        end
      end

      # 断言3: 出发日期正确（10分）
      add_assertion "出发日期正确（#{@departure_date}）", weight: 10 do
        @bookings.each do |booking|
          expect(booking.departure_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（10天后）, 实际: #{booking.departure_date}"
        end
      end

      # 断言4: 出行人数至少6人（20分）
      add_assertion "出行人数至少6人", weight: 20 do
        @bookings.each do |booking|
          expect(booking.traveler_count).to be >= 6,
            "出行人数错误。期望: 至少6人, 实际: #{booking.traveler_count}人"
        end
      end

      # 断言5: 订单总价正确（10分）
      add_assertion "订单总价正确", weight: 10 do
        @bookings.each do |booking|
          expected_total = @tour_product.price * booking.traveler_count
          expect(booking.total_price).to eq(expected_total),
            "订单总价错误。期望: #{expected_total}元, 实际: #{booking.total_price}元"
        end
      end

      # 断言6: 包含住宿和餐食（10分）
      add_assertion "包含住宿和餐食", weight: 10 do
        @bookings.each do |booking|
          product = booking.tour_group_product
          expect(product.includes_accommodation).to be true, "未包含住宿"
          expect(product.includes_meals).to be true, "未包含餐食"
        end
      end

      # 断言7: 包含门票（10分）
      add_assertion "包含门票", weight: 10 do
        @bookings.each do |booking|
          product = booking.tour_group_product
          expect(product.includes_tickets).to be true, "未包含门票"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询家庭游产品（#{@tour_product.name}）、创建订单并添加6位出行人"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        destination_id: @destination&.id,
        product_id: @tour_product&.id,
        departure_date: @departure_date&.to_s,
        agency_id: @agency&.id,
        traveler_ids: @travelers.map(&:id)
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @destination = Destination.find_by(id: state['destination_id']) if state['destination_id']
      @tour_product = TourGroupProduct.find_by(id: state['product_id']) if state['product_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @agency = TravelAgency.find_by(id: state['agency_id']) if state['agency_id']
      if state['traveler_ids']
        @travelers = Passenger.where(id: state['traveler_ids']).to_a
      end
    end
  end
end
