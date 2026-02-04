# frozen_string_literal: true

# V360: 预订海南海岛游验证器
#
# 功能描述：
#   用户需要预订海南海岛游+潜水+沙滩活动体验
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
module V357V360
  class V360HainanIslandTourValidator < BaseValidator
    self.validator_id = 360
    self.task_id = 'd444a476-5844-488c-b372-af5142d6c3e4'
    self.title = '预订海南海岛游'
    self.description = '用户需要预订海南海岛游+潜水+沙滩活动体验'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "海南椰风海韵旅行社",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "三亚蜈支洲岛",
        data_version: 0
      )

      # 创建深度游产品（海岛游）
      @tour_product = DeepTravelProduct.find_by!(
        name: "蜈支洲岛3日海岛游",
        destination: @destination,
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "island_lover_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '海岛度假者'
      end

      # 设置出发日期（15天后）
      @departure_date = Date.today + 15.days

      {
        user_id: @user.id,
        user_name: @user.name,
        destination: @destination.name,
        product_name: @tour_product.name,
        departure_date: @departure_date.to_s,
        duration: @tour_product.duration,
        traveler_count: 2,
        price: @tour_product.price
      }
    end

    def verify
      # 断言1: 创建了海岛游订单（25分）
      add_assertion "创建了海岛游订单", weight: 25 do
        all_orders = DeepTravelOrder
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到海岛游订单"
        @orders = all_orders
      end

      return if @orders.nil? || @orders.empty?

      # 断言2: 产品正确（蜈支洲岛3日海岛游）（15分）
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
            "出发日期错误。期望: #{@departure_date}（15天后）, 实际: #{order.departure_date}"
        end
      end

      # 断言4: 出行人数正确（2人）（10分）
      add_assertion "出行人数正确（2人）", weight: 10 do
        @orders.each do |order|
          expect(order.traveler_count).to eq(2),
            "出行人数错误。期望: 2人, 实际: #{order.traveler_count}人"
        end
      end

      # 断言5: 订单总价正确（10分）
      add_assertion "订单总价正确", weight: 10 do
        expected_total = @tour_product.price * 2
        @orders.each do |order|
          expect(order.total_price).to eq(expected_total),
            "订单总价错误。期望: #{expected_total}元（#{@tour_product.price} × 2人）, 实际: #{order.total_price}元"
        end
      end

      # 断言6: 包含潜水装备（15分）
      add_assertion "包含潜水装备", weight: 15 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.includes_equipment).to be true,
            "未包含潜水装备"
        end
      end

      # 断言7: 难度等级简单（10分）
      add_assertion "难度等级为简单", weight: 10 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.difficulty_level).to eq("简单"),
            "难度等级错误。期望: 简单, 实际: #{product.difficulty_level}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "#{self.class.name}#simulate method not implemented yet"
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
