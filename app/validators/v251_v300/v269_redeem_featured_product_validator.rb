# frozen_string_literal: true

module V251V300
  # V269: 给王芳兑换蜜雪冰城 5元代金券（精选推荐商品）
  #
  # 场景: 用户兑换积分商城首页精选推荐的热门商品（蜜雪冰城 5元代金券，销量最高的精选商品）
  # 考点: 精选商品筛选、热门商品兑换
  #
  # 业务流程:
  #   1. 用户输入：商品类型（精选推荐商品）、收货人（王芳）
  #   2. 系统筛选：查找精选推荐商品，按销量排序，选择销量最高的商品（蜜雪冰城 5元代金券，销量8923）
  #   3. 用户选择：选择蜜雪冰城 5元代金券（10积分+4元），确认积分和现金金额
  #   4. 提交订单：使用王芳的收货地址
  #
  # 复杂度分析:
  #   1. **精选商品筛选逻辑**（中）：需按featured=true筛选并按销量排序
  #   2. **热门商品判断**（低）：需验证销量是否>500（热门商品标准）
  #
  # 评分标准（总分100%）:
  #   - 创建了兑换订单 (25%)
  #   - 兑换的是精选商品 (25%)
  #   - 商品是蜜雪冰城 5元代金券（销量最高） (额外验证)
  #   - 商品销量较高（热门商品，>500） (10%)
  #   - 订单金额正确（10积分+4元） (10%)
  #   - 收货人信息正确（王芳） (15%)
  #   - 订单状态有效 (15%)
  class V269RedeemFeaturedProductValidator < BaseValidator
    self.validator_id = 'v269_redeem_featured_product_validator'
    self.task_id = '13ec476f-dde0-4a31-9337-db353ba25efa'
    self.title = '帮王芳兑换蜜雪冰城 5元代金券（精选推荐商品）'
    self.description = '帮王芳兑换积分商城首页精选推荐商品（蜜雪冰城 5元代金券，销量最高的精选商品，需要10积分+4元）'
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
      
      # 查询王芳的地址信息
      @wangfang_address = user.addresses.find_by!(name: '王芳', data_version: 0)
      @expected_shipping_address = [@wangfang_address.province, @wangfang_address.city, @wangfang_address.district, @wangfang_address.detail].compact.join
      @expected_contact_name = @wangfang_address.name
      @expected_contact_phone = @wangfang_address.phone
      
      membership = user.membership
      
      if membership.points < @product.price_mileage
        raise "用户积分不足。需要: #{@product.price_mileage}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < @product.price_cash
        raise "用户余额不足。需要: ¥#{@product.price_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请帮王芳在积分商城兑换首页精选推荐商品（选择销量最高的精选商品：蜜雪冰城 5元代金券）",
        requirements: {
          featured: true,
          product_name: '蜜雪冰城 5元代金券',
          highest_sales: true,
          available_products: @featured_products.map(&:name),
          recipient: '王芳'
        },
        hint: "精选商品通常是热门且性价比高的商品，请查看首页推荐区域按销量排序，选择销量最高的蜜雪冰城 5元代金券（10积分+4元），收货地址使用王芳的地址。"
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
      
      add_assertion "兑换的是精选商品", weight: 25 do
        product = @order.membership_product
        expect(product.featured).to be_truthy,
          "兑换的商品不是精选商品。商品名: #{product.name}, featured: #{product.featured}"
      end
      
      add_assertion "商品销量较高（热门商品）", weight: 10 do
        product = @order.membership_product
        expect(product.sales_count).to be > 500,
          "商品销量不足，不是热门商品。销量: #{product.sales_count}"
      end
      
      add_assertion "订单金额正确", weight: 10 do
        expect(@order.total_cash).to eq(@order.price_cash * @order.quantity)
        expect(@order.total_mileage).to eq(@order.price_mileage * @order.quantity)
      end
      
      add_assertion "收货人信息正确（王芳）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "收货人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
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
        contact_name: @expected_contact_name,
        contact_phone: @expected_contact_phone,
        shipping_address: @expected_shipping_address,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { 
        product_id: @product&.id,
        wangfang_address_id: @wangfang_address&.id
      }
    end
    
    def restore_from_state(data)
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      # 恢复地址信息
      if data['wangfang_address_id']
        @wangfang_address = Address.find(data['wangfang_address_id'])
        @expected_shipping_address = [@wangfang_address.province, @wangfang_address.city, @wangfang_address.district, @wangfang_address.detail].compact.join
        @expected_contact_name = @wangfang_address.name
        @expected_contact_phone = @wangfang_address.phone
      end
      
      @featured_products = MembershipProduct
        .where(featured: true, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
    end
  end
end
