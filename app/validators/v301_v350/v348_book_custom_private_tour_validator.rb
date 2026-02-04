# frozen_string_literal: true

# V368: 预订私人定制游（专属行程+专业团队）验证器
#
# 功能描述：
#   用户需要预订私人定制游，包含专属行程设计和专业团队服务
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
  class V348BookCustomPrivateTourValidator < BaseValidator
    self.validator_id = 348
    self.task_id = '5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a0b'
    self.title = '预订私人定制游（专属行程+专业团队）'
    self.description = '用户需要预订私人定制游，包含专属行程设计和专业团队服务'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "高端定制旅游工作室",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "云南丽江古城",
        data_version: 0
      )

      # 创建私人定制深度游产品
      @tour_product = DeepTravelProduct.find_by!(
        name: "丽江私人定制7日深度游",
        destination: @destination,
        data_version: 0
      )

      # 创建私人导游
      @guide = DeepTravelGuide.find_by!(
        name: "张老师",
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "custom_tour_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '定制游客户'
      end

      # 设置出发日期
      @departure_date = Date.today + 14.days

      {
        user_id: @user.id,
        user_name: @user.name,
        destination: @destination.name,
        product_name: @tour_product.name,
        departure_date: @departure_date.to_s,
        duration: @tour_product.duration,
        traveler_count: 4,
        price: @tour_product.price,
        guide_name: @guide.name,
        service_type: "私人定制游"
      }
    end

    def verify
      # 断言1: 创建了私人定制游订单（30分）
      add_assertion "创建了私人定制游订单", weight: 30 do
        all_orders = DeepTravelBooking
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到私人定制游订单"
        @orders = all_orders
      end

      return if @orders.nil? || @orders.empty?

      # 断言2: 产品正确（丽江私人定制7日深度游）（15分）
      add_assertion "产品正确（#{@tour_product.name}）", weight: 15 do
        @orders.each do |order|
          expect(order.deep_travel_product.name).to eq(@tour_product.name),
            "产品错误。期望: #{@tour_product.name}, 实际: #{order.deep_travel_product.name}"
        end
      end

      # 断言3: 出发日期正确（15分）
      add_assertion "出发日期正确（#{@departure_date}）", weight: 15 do
        @orders.each do |order|
          expect(order.departure_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（14天后）, 实际: #{order.departure_date}"
        end
      end

      # 断言4: 出行人数正确（至少4人）（10分）
      add_assertion "出行人数正确（至少4人）", weight: 10 do
        @orders.each do |order|
          traveler_count = order.booking_travelers.count
          expect(traveler_count).to be >= 4,
            "出行人数错误。期望: 至少4人, 实际: #{traveler_count}人"
        end
      end

      # 断言5: 订单总价正确（15分）
      add_assertion "订单总价正确", weight: 15 do
        @orders.each do |order|
          traveler_count = order.booking_travelers.count
          expected_total = @tour_product.price * traveler_count
          expect(order.total_price).to be >= expected_total,
            "订单总价错误。期望: 至少#{expected_total}元, 实际: #{order.total_price}元"
        end
      end

      # 断言6: 旅行社评分为满分5.0（15分）
      add_assertion "旅行社评分为满分5.0", weight: 15 do
        @orders.each do |order|
          agency = order.deep_travel_product.travel_agency
          expect(agency.rating).to eq(5.0),
            "旅行社评分错误。期望: 5.0, 实际: #{agency.rating}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询私人定制游产品（#{@tour_product.name}）、创建订单"
    end

    def execution_state_data
      {
        user_id: @user&.id,
        destination_id: @destination&.id,
        product_id: @tour_product&.id,
        guide_id: @guide&.id,
        departure_date: @departure_date&.to_s,
        agency_id: @agency&.id
      }
    end

    def restore_from_state(state)
      @user = User.find_by(id: state['user_id']) if state['user_id']
      @destination = Destination.find_by(id: state['destination_id']) if state['destination_id']
      @tour_product = DeepTravelProduct.find_by(id: state['product_id']) if state['product_id']
      @guide = DeepTravelGuide.find_by(id: state['guide_id']) if state['guide_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @agency = TravelAgency.find_by(id: state['agency_id']) if state['agency_id']
    end
  end
end
