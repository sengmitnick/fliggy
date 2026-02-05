# frozen_string_literal: true

module V251V300
  # V276: 兑换高端商品（茅台）
  #
  # 场景: 用户使用大量积分兑换高端奢侈品（如茅台酒）
  # 考点: 高价值商品兑换、大额积分消耗
  class V276RedeemLuxuryProductValidator < BaseValidator
    self.validator_id = 'v276_redeem_luxury_product_validator'
    self.task_id = '5c26767f-392a-4da8-a10f-cb8b2b1c39aa'
    self.title = '兑换高端商品（茅台）'
    self.description = '用户使用大量积分兑换高端奢侈品（如茅台酒）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '茅台飞天53度 500ml'
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        membership.update!(points: required_points + 5000)
      end
      
      if user.balance < required_cash
        user.update!(balance: required_cash + 1000)
      end
      
      {
        task: "请在积分商城兑换：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          category: '年货精选',
          is_luxury: true
        },
        hint: "这是高端商品，需要大量积分（#{@product.price_mileage}积分）和现金（#{@product.price_cash}元）。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 25 do
        all_orders = MembershipOrder
          .joins(:membership_product)
          .includes(:membership_product)
          .where(membership_products: { name: @product_name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @order = all_orders.first
        expect(@order).not_to be_nil, "未找到#{@product_name}的兑换订单"
      end
      
      return if @order.nil?
      
      add_assertion "商品正确（#{@product_name}）", weight: 15 do
        expect(@order.membership_product.name).to eq(@product_name),
          "商品名称错误。期望: #{@product_name}, 实际: #{@order.membership_product.name}"
      end
      
      add_assertion "这是高价值商品（积分≥20000）", weight: 20 do
        expect(@order.price_mileage).to be >= 20000,
          "商品积分价值不足，不是高端商品。期望: ≥20000积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "这是高价值商品（现金≥1500元）", weight: 20 do
        expect(@order.price_cash).to be >= 1500,
          "商品现金价值不足，不是高端商品。期望: ≥1500元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@order.status).to be_in(['pending', 'paid', 'shipping', 'completed']),
          "订单状态无效。期望: pending/paid/shipping/completed, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      MembershipOrder.create!(
        user: user,
        membership_product: @product,
        quantity: 1,
        price_cash: @product.price_cash,
        price_mileage: @product.price_mileage,
        total_cash: @product.price_cash,
        total_mileage: @product.price_mileage,
        contact_name: user.name,
        contact_phone: user.phone || '13800138000',
        shipping_address: '贵州省贵阳市云岩区中华北路1号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_name: @product_name, product_id: @product&.id }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
