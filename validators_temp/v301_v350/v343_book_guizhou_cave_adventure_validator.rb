# frozen_string_literal: true

# V363: 预订贵州溶洞探险验证器
#
# 功能描述：
#   用户需要预订贵州溶洞探险+苗寨体验
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
  class V343BookGuizhouCaveAdventureValidator < BaseValidator
    self.validator_id = 343
    self.task_id = '9c4d5e6f-7a8b-1c2d-3e4f-5a6b7c8d9e0f'
    self.title = '预订贵州溶洞探险+苗寨体验'
    self.description = '用户需要预订贵州溶洞探险，包含溶洞游览和苗寨文化体验'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "贵州民族风情旅行社",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "织金洞",
        data_version: 0
      )

      # 创建深度游产品（溶洞探险+苗寨体验）
      @tour_product = DeepTravelProduct.find_by!(
        name: "贵州溶洞探险+苗寨文化4日游",
        destination: @destination,
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "cave_explorer_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '溶洞探险者'
      end

      # 设置出发日期（12天后）
      @departure_date = Date.today + 12.days

      {
        user_id: @user.id,
        user_name: @user.name,
        destination: @destination.name,
        product_name: @tour_product.name,
        departure_date: @departure_date.to_s,
        duration: @tour_product.duration,
        traveler_count: 2,
        price: @tour_product.price,
        features: "溶洞探险+苗寨体验"
      }
    end

    def verify
      # 断言1: 创建了溶洞探险订单（25分）
      add_assertion "创建了溶洞探险订单", weight: 25 do
        all_orders = DeepTravelBooking
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到溶洞探险订单"
        @orders = all_orders
      end

      return if @orders.nil? || @orders.empty?

      # 断言2: 产品正确（贵州溶洞探险+苗寨文化4日游）（15分）
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
            "出发日期错误。期望: #{@departure_date}（12天后）, 实际: #{order.departure_date}"
        end
      end

      # 断言4: 出行人数正确（2人）（10分）
      add_assertion "出行人数正确（2人）", weight: 10 do
        @orders.each do |order|
          traveler_count = order.booking_travelers.count
          expect(traveler_count).to be >= 2,
            "出行人数错误。期望: 至少2人, 实际: #{traveler_count}人"
        end
      end

      # 断言5: 订单总价正确（10分）
      add_assertion "订单总价正确", weight: 10 do
        @orders.each do |order|
          traveler_count = order.booking_travelers.count
          expected_total = @tour_product.price * traveler_count
          expect(order.total_price).to eq(expected_total),
            "订单总价错误。期望: #{expected_total}元, 实际: #{order.total_price}元"
        end
      end

      # 断言6: 包含探险装备（15分）
      add_assertion "包含探险装备", weight: 15 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.includes_equipment).to be true, "未包含探险装备"
        end
      end

      # 断言7: 难度等级为简单（10分）
      add_assertion "难度等级为简单", weight: 10 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.difficulty_level).to eq("简单"),
            "难度等级错误。期望: 简单, 实际: #{product.difficulty_level}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询贵州溶洞探险产品（#{@tour_product.name}）、创建订单"
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
      @tour_product = DeepTravelProduct.find_by(id: state['product_id']) if state['product_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @agency = TravelAgency.find_by(id: state['agency_id']) if state['agency_id']
    end
  end
end
