# frozen_string_literal: true

module V251V300
  # V268: 使用大量积分兑换高价商品
  #
  # 场景: 用户使用大量积分+现金兑换高价商品（如京东E卡100元）
  # 考点: 高价商品兑换、积分消耗验证
  class V268RedeemHighPriceProductWithMileageValidator < BaseValidator
    self.validator_id = 'v268_redeem_high_price_product_with_mileage_validator'
    self.task_id = 'f13f0g4b-3c5d-5e2f-9b6g-7d8e9f0g1h2c'
    self.title = '使用大量积分兑换高价商品'
    self.description = '用户使用大量积分+现金兑换高价商品（如京东E卡）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '京东E卡 100元'
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      raise "用户无会员记录" if membership.nil?
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        membership.update!(points: required_points + 500)
      end
      
      if user.balance < required_cash
        user.update!(balance: required_cash + 200)
      end
      
      {
        task: "请在积分商城兑换：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash
        },
        hint: "该商品需要大量积分（#{@product.price_mileage}积分）才能兑换。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 30 do
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
        expect(@order.membership_product.name).to eq(@product_name)
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 20 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "现金金额正确（#{@product.price_cash}元）", weight: 20 do
        expect(@order.price_cash).to eq(@product.price_cash),
          "现金金额错误。期望: #{@product.price_cash}元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@order.status).to be_in(['pending', 'paid', 'shipping', 'completed'])
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
        shipping_address: '上海市浦东新区陆家嘴环路1000号',
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
