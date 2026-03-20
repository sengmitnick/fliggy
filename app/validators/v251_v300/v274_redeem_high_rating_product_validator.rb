# frozen_string_literal: true

module V251V300
  # V274: 帮张三在积分商城按评分排序，选择评分最高的商品兑换（≥ 4.8分）
  #
  # 场景: 用户按评分降序排序，选择评分最高的商品兑换
  # 考点: 评分排序、质量保证
  #
  # 业务流程:
  #   1. 用户输入：需要在积分商城按评分降序排序，选择评分最高的商品兑换
  #   2. 系统排序：按评分降序排列商品，同评分按销量降序
  #   3. 商品筛选：选择评分≥4.8分的高评分商品
  #   4. 提交订单：创建订单
  #
  # 复杂度分析:
  #   1. **评分排序**（低）：需要按评分降序排列
  #   2. **高评分识别**（低）：选择排序后的第一个高评分商品
  #   3. **订单创建**（低）：创建单个订单
  #
  # 评分标准（总分100%）:
  #   - 创建兑换订单 (20%)
  #   - 兑换的是高评分商品（≥4.8分） (35%)
  #   - 订单金额正确 (20%)
  #   - 订单已支付 (15%)
  #   - 收货地址正确 (10%)
  class V274RedeemHighRatingProductValidator < BaseValidator
    self.validator_id = 'v274_redeem_high_rating_product_validator'
    self.task_id = 'fdc187fc-0997-427d-9d9f-7a3241a8e088'
    self.title = '帮张三在积分商城按评分排序，选择评分最高的商品兑换（≥ 4.8分）'
    self.description = '帮张三在积分商城按评分排序，选择评分最高的商品兑换（≥ 4.8分）'
    self.timeout_seconds = 300
    
    def prepare
      # 查找张三的收货地址
      zhangsan = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_address = zhangsan.addresses.where(data_version: 0).first!
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      
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
      membership = zhangsan.membership
      
      if membership.points < @product.price_mileage
        raise "用户积分不足。需要: #{@product.price_mileage}积分，当前: #{membership.points}积分"
      end
      
      if zhangsan.balance < @product.price_cash
        raise "用户余额不足。需要: ¥#{@product.price_cash}，当前: ¥#{zhangsan.balance}"
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
      add_assertion "创建了兑换订单", weight: 20 do
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
      
      add_assertion "订单金额正确", weight: 20 do
        expect(@order.total_cash).to eq(@order.price_cash * @order.quantity),
          "现金金额错误。期望: ¥#{@order.price_cash * @order.quantity}, 实际: ¥#{@order.total_cash}"
        expect(@order.total_mileage).to eq(@order.price_mileage * @order.quantity),
          "积分金额错误。期望: #{@order.price_mileage * @order.quantity}积分, 实际: #{@order.total_mileage}积分"
      end
      
      add_assertion "订单已支付", weight: 15 do
        expect(@order.status).to eq('paid'),
          "订单状态错误。期望: paid, 实际: #{@order.status}"
      end
      
      add_assertion "收货地址正确", weight: 10 do
        expect(@order.shipping_address).to eq(@expected_shipping_address),
          "收货地址错误。期望: #{@expected_shipping_address}, 实际: #{@order.shipping_address}"
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
        shipping_address: @expected_shipping_address,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { 
        product_id: @product&.id, 
        min_rating: @min_rating,
        zhangsan_address_id: @zhangsan_address&.id,
        expected_shipping_address: @expected_shipping_address
      }
    end
    
    def restore_from_state(data)
      @min_rating = data['min_rating']
      @expected_shipping_address = data['expected_shipping_address']
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
      end
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
