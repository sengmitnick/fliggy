# frozen_string_literal: true

module V251V300
  # V276: 帮张三使用大量积分兑换高端奢侈品（茅台飞天53度 500ml）
  #
  # 场景: 用户使用大量积分兑换高端奢侈品（如茅台酒）
  # 考点: 高价值商品兑换、大额积分消耗
  #
  # 业务流程:
  #   1. 用户输入：需要在积分商城兑换高端奢侈品（茅台飞天53度 500ml）
  #   2. 商品查找：查找指定的茅台飞天商品
  #   3. 积分验证：确认用户积分和余额充足（需要大量积分≥20000 + 现金≥1500元）
  #   4. 提交订单：创建订单并支付
  #
  # 复杂度分析:
  #   1. **商品查找**（低）：按商品名称精确查找
  #   2. **积分验证**（低）：验证用户积分和余额是否充足
  #   3. **订单创建**（低）：创建单个高价值订单
  #
  # 评分标准（总分100%）:
  #   - 创建兑换订单 (20%)
  #   - 商品正确（茅台飞天53度 500ml） (15%)
  #   - 这是高价值商品（积分≥20000 + 现金≥1500元） (40%)
  #   - 订单已支付 (15%)
  #   - 收货地址正确 (10%)
  class V276RedeemLuxuryProductValidator < BaseValidator
    self.validator_id = 'v276_redeem_luxury_product_validator'
    self.task_id = '5c26767f-392a-4da8-a10f-cb8b2b1c39aa'
    self.title = '帮张三使用大量积分兑换高端奢侈品（茅台飞天53度 500ml）'
    self.description = '帮张三使用大量积分兑换高端奢侈品（茅台飞天53度 500ml）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '茅台飞天53度 500ml'
      
      # 查找张三的收货地址
      zhangsan = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_address = zhangsan.addresses.where(data_version: 0).first!
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 确保用户有足够的积分和余额
      membership = zhangsan.membership
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if zhangsan.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{zhangsan.balance}"
      end
      
      {
        task: "请在积分商城兑换：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          rating: @product.rating,
          sales_count: @product.sales_count,
          category: '年货精选',
          is_luxury: true
        },
        hint: "这是高端商品，需要大量积分（#{@product.price_mileage}积分）和现金（#{@product.price_cash}元）。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 20 do
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
      
      add_assertion "这是高价值商品（积分≥20000 + 现金≥1500元）", weight: 40 do
        expect(@order.price_mileage).to be >= 20000,
          "商品积分价值不足，不是高端商品。期望: ≥20000积分, 实际: #{@order.price_mileage}积分"
        expect(@order.price_cash).to be >= 1500,
          "商品现金价值不足，不是高端商品。期望: ≥1500元, 实际: #{@order.price_cash}元"
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
        product_name: @product_name, 
        product_id: @product&.id,
        zhangsan_address_id: @zhangsan_address&.id,
        expected_shipping_address: @expected_shipping_address
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @expected_shipping_address = data['expected_shipping_address']
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
      end
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
