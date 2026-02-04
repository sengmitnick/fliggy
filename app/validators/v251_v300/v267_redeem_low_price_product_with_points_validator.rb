# frozen_string_literal: true

module V251V300
  # V267: 使用会员积分兑换低价商品（积分+现金混合支付）
  #
  # 场景: 用户使用少量积分+现金兑换热门低价商品（如咖啡券）
  # 考点: 积分商城基础功能、混合支付逻辑
  class V267RedeemLowPriceProductWithPointsValidator < BaseValidator
    self.validator_id = 'v267_redeem_low_price_product_with_points_validator'
    self.task_id = 'e02e9f3a-2b4c-4d1b-8a5f-6c7d8e9f0a1b'
    self.title = '使用会员积分兑换低价商品'
    self.description = '用户使用少量积分+现金兑换热门低价商品（如咖啡券）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '瑞幸咖啡券 9.9元'
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 检查商品价格
      raise "商品价格设置错误" if @product.price_cash <= 0 && @product.price_mileage <= 0
      
      # 检查用户积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      raise "用户无会员记录" if membership.nil?
      
      # 确保用户有足够的积分和余额
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        membership.update!(points: required_points + 100)
      end
      
      if user.balance < required_cash
        user.update!(balance: required_cash + 100)
      end
      
      {
        task: "请在积分商城兑换商品：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          payment_method: '积分+现金'
        },
        hint: "该商品需要使用#{@product.price_mileage}积分 + #{@product.price_cash}元进行兑换。"
      }
    end
    
    def verify
      add_assertion "创建了积分兑换订单", weight: 30 do
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
      
      add_assertion "商品信息正确（#{@product_name}）", weight: 15 do
        expect(@order.membership_product.name).to eq(@product_name),
          "商品名称错误。期望: #{@product_name}, 实际: #{@order.membership_product.name}"
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 15 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "现金金额正确（#{@product.price_cash}元）", weight: 15 do
        expect(@order.price_cash).to eq(@product.price_cash),
          "现金金额错误。期望: #{@product.price_cash}元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "订单数量正确（至少1个）", weight: 10 do
        expect(@order.quantity).to be >= 1,
          "订单数量错误。期望: ≥1, 实际: #{@order.quantity}"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        valid_statuses = ['pending', 'paid', 'shipping', 'completed']
        expect(@order.status).to be_in(valid_statuses),
          "订单状态无效。期望: #{valid_statuses.join('/')}, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建积分兑换订单
      MembershipOrder.create!(
        user: user,
        membership_product: @product,
        quantity: 1,
        price_cash: @product.price_cash,
        price_mileage: @product.price_mileage,
        total_cash: @product.price_cash * 1,
        total_mileage: @product.price_mileage * 1,
        contact_name: user.name,
        contact_phone: user.phone || '13800138000',
        shipping_address: '北京市朝阳区建国门外大街1号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        product_name: @product_name,
        product_id: @product&.id
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
