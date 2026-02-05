# frozen_string_literal: true

# V358: 预订云南民族风情游验证器
#
# 功能描述：
#   用户需要预订云南民族风情游+少数民族体验+传统文化
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
  class V338YunnanEthnicTourValidator < BaseValidator
    self.validator_id = 338
    self.task_id = '1f929a34-f958-46a1-ab50-63fe30b48882'
    self.title = '预订云南民族风情游'
    self.description = '用户需要预订云南民族风情游+少数民族体验+传统文化'
    self.timeout_seconds = 180

    def prepare
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "云南彩云之南旅行社",
        data_version: 0
      )

      # 创建目的地
      @destination = Destination.find_by!(
        name: "大理古城",
        data_version: 0
      )

      # 创建跟团游产品（民族风情游）
      @tour_product = TourGroupProduct.find_by!(
        name: "大理白族风情5日游",
        destination: @destination,
        data_version: 0
      )

      # 创建测试用户
      @user = User.find_by!(
        email: "ethnic_culture_#{SecureRandom.hex(4)}@example.com",
        data_version: @data_version
      ) do |u|
        u.password = 'password123'
        u.name = '文化爱好者'
      end

      # 设置出发日期（10天后）
      @departure_date = Date.today + 10.days

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
      # 断言1: 创建了跟团游订单（25分）
      add_assertion "创建了民族风情游订单", weight: 25 do
        all_orders = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        expect(all_orders).not_to be_empty, "未找到民族风情游订单"
        @orders = all_orders
      end

      return if @orders.nil? || @orders.empty?

      # 断言2: 产品正确（大理白族风情5日游）（15分）
      add_assertion "产品正确（#{@tour_product.name}）", weight: 15 do
        @orders.each do |order|
          expect(order.tour_group_product.name).to eq(@tour_product.name),
            "产品错误。期望: #{@tour_product.name}, 实际: #{order.tour_group_product.name}"
        end
      end

      # 断言3: 出发日期正确（15分）
      add_assertion "出发日期正确（#{@departure_date}）", weight: 15 do
        @orders.each do |order|
          expect(order.departure_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（10天后）, 实际: #{order.departure_date}"
        end
      end

      # 断言4: 出行人数正确（2人）（10分）
      add_assertion "出行人数正确（2人）", weight: 10 do
        @orders.each do |order|
          expect(order.participant_count).to eq(2),
            "出行人数错误。期望: 2人, 实际: #{order.participant_count}人"
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

      # 断言6: 包含餐饮（10分）
      add_assertion "包含餐饮", weight: 10 do
        @orders.each do |order|
          product = order.tour_group_product
          expect(product.includes_meals).to be true,
            "未包含餐饮"
        end
      end

      # 断言7: 包含住宿（15分）
      add_assertion "包含住宿", weight: 15 do
        @orders.each do |order|
          product = order.tour_group_product
          expect(product.includes_accommodation).to be true,
            "未包含住宿"
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
      @tour_product = TourGroupProduct.find_by(id: state['product_id']) if state['product_id']
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @agency = TravelAgency.find_by(id: state['agency_id']) if state['agency_id']
    end
  end
end
