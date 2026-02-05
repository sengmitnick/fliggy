# frozen_string_literal: true

# V357: 预订新疆沙漠探险验证器
#
# 功能描述：
#   用户需要预订新疆沙漠探险+骆驼骑行+星空露营体验
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
  class V337XinjiangDesertAdventureValidator < BaseValidator
    self.validator_id = 337
    self.task_id = 'c5ecf02b-b53e-40d7-8c74-6042f6e3f148'
    self.title = '预订新疆沙漠探险'
    self.description = '用户需要预订新疆沙漠探险+骆驼骑行+星空露营体验'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "新疆天山探险旅行社",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "塔克拉玛干沙漠",
        data_version: 0
      )

      # 创建深度游产品（沙漠探险）
      @tour_product = DeepTravelProduct.find_by!(
        name: "塔克拉玛干沙漠3日探险",
        destination: @destination,
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "desert_explorer_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '沙漠探险家'
      end

      # 设置出发日期（7天后）
      @departure_date = Date.today + 7.days

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
      # 断言1: 创建了深度游订单（25分）
      add_assertion "创建了沙漠探险订单", weight: 25 do
        all_orders = DeepTravelOrder
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到沙漠探险订单"
        @orders = all_orders
      end

      return if @orders.nil? || @orders.empty?

      # 断言2: 产品正确（塔克拉玛干沙漠3日探险）（15分）
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
            "出发日期错误。期望: #{@departure_date}（7天后）, 实际: #{order.departure_date}"
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

      # 断言6: 包含探险装备（15分）
      add_assertion "包含探险装备", weight: 15 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.includes_equipment).to be true,
            "未包含探险装备"
        end
      end

      # 断言7: 难度等级适中（10分）
      add_assertion "难度等级为中等", weight: 10 do
        @orders.each do |order|
          product = order.deep_travel_product
          expect(product.difficulty_level).to eq("中等"),
            "难度等级错误。期望: 中等, 实际: #{product.difficulty_level}"
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
