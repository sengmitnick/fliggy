# frozen_string_literal: true

module V251V300
  # V272: 帮张三在积分商城按销量排序，选择销量最高的商品兑换（蜜雪冰城 5元代金券）
  #
  # 场景: 用户按销量降序排序，选择销量最高的商品兑换
  # 考点: 排序功能、热销商品识别
  #
  # 业务流程:
  #   1. 用户输入：需要在积分商城按销量排序，选择销量最高的商品兑换
  #   2. 系统排序：按销量降序排列商品，销量最高的是蜜雪冰城 5元代金券（销量8927）
  #   3. 商品信息：10积分 + 4元
  #   4. 提交订单：创建订单，总计10积分 + 4元
  #
  # 复杂度分析:
  #   1. **销量排序**（低）：需要按sales_count降序排列
  #   2. **热销商品识别**（低）：选择排序后的第一个商品
  #   3. **订单创建**（低）：创建单个订单
  #
  # 评分标准（总分100%）:
  #   - 创建了兑换订单（20分）
  #   - 兑换的是销量前3的热销商品（35分）
  #   - 订单金额正确（20分）
  #   - 订单已支付（15分）
  #   - 收货地址正确（10分）
  class V272RedeemTopSalesProductValidator < BaseValidator
    self.validator_id = 'v272_redeem_top_sales_product_validator'
    self.task_id = '5d612ca8-0765-4fc4-ac2a-92c6e7b84075'
    self.title = '帮张三在积分商城按销量排序，选择销量最高的商品兑换（蜜雪冰城 5元代金券）'
    self.description = '帮张三在积分商城按销量排序，选择销量最高的商品兑换（蜜雪冰城 5元代金券 10积分+4元，销量8927）'
    self.timeout_seconds = 300
    
    def prepare
      # 查找张三的收货地址
      zhangsan = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_address = zhangsan.addresses.where(data_version: 0).first!
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      
      # 查找销量最高的商品
      @top_sales_products = MembershipProduct
        .where(data_version: 0)
        .order(sales_count: :desc)
        .limit(3)
        .to_a
      
      raise "未找到商品" if @top_sales_products.empty?
      
      @product = @top_sales_products.first
      @product_name = @product.name
      @min_sales = @product.sales_count
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      if membership.points < @product.price_mileage
        raise "用户积分不足。需要: #{@product.price_mileage}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < @product.price_cash
        raise "用户余额不足。需要: ¥#{@product.price_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请在积分商城按销量排序，选择销量最高的商品（#{@product_name}）进行兑换",
        requirements: {
          sort_by: 'sales_count',
          order: 'desc',
          product_name: @product_name,
          sales_count: @min_sales,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          top_products: @top_sales_products.map { |p| { name: p.name, sales: p.sales_count } }
        },
        hint: "销量最高的商品是#{@product_name}（销量#{@min_sales}，#{@product.price_mileage}积分+#{@product.price_cash}元）。"
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
      
      add_assertion "兑换的是销量前3的热销商品", weight: 35 do
        product = @order.membership_product
        top_3_sales = @top_sales_products.map(&:sales_count)
        
        expect(top_3_sales).to include(product.sales_count),
          "商品不在销量前3。商品: #{product.name}（销量#{product.sales_count}），前3名销量: #{top_3_sales.join('、')}"
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
        min_sales: @min_sales,
        zhangsan_address_id: @zhangsan_address&.id,
        expected_shipping_address: @expected_shipping_address
      }
    end
    
    def restore_from_state(data)
      @min_sales = data['min_sales']
      @expected_shipping_address = data['expected_shipping_address']
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
      end
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      @top_sales_products = MembershipProduct
        .where(data_version: 0)
        .order(sales_count: :desc)
        .limit(3)
        .to_a
    end
  end
end
