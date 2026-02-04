# frozen_string_literal: true

module V251V300
  # V274: 按评分排序选择高评分商品
  #
  # 场景: 用户按评分降序排序，选择评分最高的商品兑换
  # 考点: 评分排序、质量保证
  class V274RedeemHighRatingProductValidator < BaseValidator
    self.validator_id = 'v274_redeem_high_rating_product_validator'
    self.task_id = 'l79l6m0h-9i1j-1k8l-5h2m-3j4k5l6m7n8i'
    self.title = '按评分排序选择高评分商品'
    self.description = '用户按评分降序排序，选择评分最高的商品兑换'
    self.timeout_seconds = 300
    
    def prepare
      # 查找评分最高的商品
      @high_rating_products = MembershipProduct
        .where(data_version: 0)
        .where('rating >= 4.8')
        .order(rating: :desc, sales_count: :desc)
        .limit(5)
        .to_a
      
      raise "未找到高评分商品" if @high_rating_products.empty?
      
      @product = @high_rating_products.first
      @product_name = @product.name
      @min_rating = 4.8
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      if membership.points < @product.price_mileage
        membership.update!(points: @product.price_mileage + 1000)
      end
      
      if user.balance < @product.price_cash
        user.update!(balance: @product.price_cash + 300)
      end
      
      {
        task: "请在积分商城按评分降序排序，选择评分最高的商品进行兑换",
        requirements: {
          sort_by: 'rating',
          order: 'desc',
          min_rating: @min_rating,
          high_rating_products: @high_rating_products.map { |p| { name: p.name, rating: p.rating } }
        },
        hint: "高评分商品（≥4.8分）代表用户满意度高、质量有保障。"
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
      
      add_assertion "兑换的是高评分商品（≥#{@min_rating}分）", weight: 35 do
        product = @order.membership_product
        expect(product.rating).to be >= @min_rating,
          "商品评分不足。期望: ≥#{@min_rating}分, 实际: #{product.rating}分"
      end
      
      add_assertion "商品信息完整", weight: 15 do
        product = @order.membership_product
        expect(product.name).not_to be_empty
        expect(product.rating).to be > 0
      end
      
      add_assertion "订单金额正确", weight: 10 do
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
        shipping_address: '西安市雁塔区高新路88号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_id: @product&.id, min_rating: @min_rating }
    end
    
    def restore_from_state(data)
      @min_rating = data['min_rating']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      @high_rating_products = MembershipProduct
        .where(data_version: 0)
        .where('rating >= 4.8')
        .order(rating: :desc, sales_count: :desc)
        .limit(5)
        .to_a
    end
  end
end
