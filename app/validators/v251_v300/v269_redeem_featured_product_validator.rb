# frozen_string_literal: true

module V251V300
  # V269: 兑换精选推荐商品
  #
  # 场景: 用户兑换积分商城首页精选推荐的热门商品
  # 考点: 精选商品筛选、热门商品兑换
  class V269RedeemFeaturedProductValidator < BaseValidator
    self.validator_id = 'v269_redeem_featured_product_validator'
    self.task_id = 'g24g1h5c-4d6e-6f3g-0c7h-8e9f0g1h2i3d'
    self.title = '兑换精选推荐商品'
    self.description = '用户兑换积分商城首页精选推荐的热门商品'
    self.timeout_seconds = 300
    
    def prepare
      # 查找精选商品
      @featured_products = MembershipProduct
        .where(featured: true, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
      
      raise "未找到精选商品" if @featured_products.empty?
      
      # 选择第一个精选商品
      @product = @featured_products.first
      @product_name = @product.name
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      if membership.points < @product.price_mileage
        membership.update!(points: @product.price_mileage + 500)
      end
      
      if user.balance < @product.price_cash
        user.update!(balance: @product.price_cash + 200)
      end
      
      {
        task: "请在积分商城兑换首页精选推荐商品（选择任意一个精选商品即可）",
        requirements: {
          featured: true,
          available_products: @featured_products.map(&:name)
        },
        hint: "精选商品通常是热门且性价比高的商品，请查看首页推荐区域。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 25 do
        @all_orders = MembershipOrder
          .joins(:membership_product)
          .includes(:membership_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@all_orders).not_to be_empty, "未找到任何兑换订单"
        @order = @all_orders.first
      end
      
      return if @all_orders.nil? || @all_orders.empty?
      
      add_assertion "兑换的是精选商品", weight: 30 do
        product = @order.membership_product
        expect(product.featured).to be_truthy,
          "兑换的商品不是精选商品。商品名: #{product.name}, featured: #{product.featured}"
      end
      
      add_assertion "商品销量较高（热门商品）", weight: 15 do
        product = @order.membership_product
        expect(product.sales_count).to be > 500,
          "商品销量不足，不是热门商品。销量: #{product.sales_count}"
      end
      
      add_assertion "订单金额正确", weight: 15 do
        expect(@order.total_cash).to eq(@order.price_cash * @order.quantity)
        expect(@order.total_mileage).to eq(@order.price_mileage * @order.quantity)
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
        shipping_address: '广州市天河区珠江新城花城大道5号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_id: @product&.id }
    end
    
    def restore_from_state(data)
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      @featured_products = MembershipProduct
        .where(featured: true, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
    end
  end
end
