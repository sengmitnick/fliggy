# frozen_string_literal: true

# V361: 预订东北冰雪游验证器
#
# 功能描述：
#   用户需要预订东北冰雪游+雾凇+冰雕+狗拉雪橇体验
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
  class V341BookNortheastIceSnowTourValidator < BaseValidator
    self.validator_id = 341
    self.task_id = '8f3d4c2a-1e5b-4d7c-9a3f-2b6e8c4d5f7a'
    self.title = '预订东北冰雪游+雾凇+冰雕+狗拉雪橇'
    self.description = '用户需要预订东北冰雪游，包含雾凇观赏、冰雕游览和狗拉雪橇体验'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "东北冰雪旅游集团",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "吉林雾凇岛",
        data_version: 0
      )

      # 创建跟团游产品（东北冰雪游）
      @tour_product = TourGroupProduct.find_by!(
        name: "东北冰雪奇缘5日游",
        destination: @destination.name,
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "ice_snow_traveler_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '冰雪旅行者'
      end

      # 设置出发日期（15天后，冬季时间）
      @departure_date = Date.today + 15.days

      {
        user_id: @user.id,
        user_name: @user.name,
        destination: @destination.name,
        product_name: @tour_product.name,
        departure_date: @departure_date.to_s,
        duration: @tour_product.duration,
        traveler_count: 2,
        price: @tour_product.price,
        features: "雾凇观赏+冰雕游览+狗拉雪橇体验"
      }
    end

    def verify
      # 断言1: 创建了东北冰雪游订单（25分）
      add_assertion "创建了东北冰雪游订单", weight: 25 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_bookings).not_to be_empty, "未找到东北冰雪游订单"
        @bookings = all_bookings
      end

      return if @bookings.nil? || @bookings.empty?

      # 断言2: 产品正确（东北冰雪奇缘5日游）（15分）
      add_assertion "产品正确（#{@tour_product.name}）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.tour_group_product.name).to eq(@tour_product.name),
            "产品错误。期望: #{@tour_product.name}, 实际: #{booking.tour_group_product.name}"
        end
      end

      # 断言3: 出发日期正确（15分）
      add_assertion "出发日期正确（#{@departure_date}）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.departure_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（15天后）, 实际: #{booking.departure_date}"
        end
      end

      # 断言4: 出行人数正确（2人）（10分）
      add_assertion "出行人数正确（2人）", weight: 10 do
        @bookings.each do |booking|
          expect(booking.traveler_count).to be >= 2,
            "出行人数错误。期望: 至少2人, 实际: #{booking.traveler_count}人"
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

      # 断言6: 包含住宿和餐食（15分）
      add_assertion "包含住宿和餐食", weight: 15 do
        @bookings.each do |booking|
          product = booking.tour_group_product
          expect(product.includes_accommodation).to be true, "未包含住宿"
          expect(product.includes_meals).to be true, "未包含餐食"
        end
      end

      # 断言7: 包含门票（雾凇岛+冰雕展）（10分）
      add_assertion "包含门票", weight: 10 do
        @bookings.each do |booking|
          product = booking.tour_group_product
          expect(product.includes_tickets).to be true, "未包含门票"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询东北冰雪游产品（#{@tour_product.name}）、创建订单"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        destination_id: @destination&.id,
        product_id: @tour_product&.id,
        departure_date: @departure_date&.to_s,
        agency_id: @agency&.id
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @destination = Destination.find_by(id: state['destination_id']) if state['destination_id']
      @tour_product = TourGroupProduct.find_by(id: state['product_id']) if state['product_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @agency = TravelAgency.find_by(id: state['agency_id']) if state['agency_id']
    end
  end
end
