# frozen_string_literal: true

module V251V300
  # V272: 按销量排序选择热销商品
  #
  # 场景: 用户按销量降序排序，选择销量最高的商品兑换
  # 考点: 排序功能、热销商品识别
  class V272RedeemTopSalesProductValidator < BaseValidator
    self.validator_id = 'v272_redeem_top_sales_product_validator'
    self.task_id = '5d612ca8-0765-4fc4-ac2a-92c6e7b84075'
    self.title = '给张三兑换销量最高的热门商品'
    self.description = '帮张三在积分商城按销量排序，选择销量最高的商品兑换'
    self.timeout_seconds = 300
    
    def prepare
      @expected_shipping_address = '成都市武侯区天府大道北段1700号'
      
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
        task: "请在积分商城按销量排序，选择销量最高的商品进行兑换",
        requirements: {
          sort_by: 'sales_count',
          order: 'desc',
          top_products: @top_sales_products.map { |p| { name: p.name, sales: p.sales_count } }
        },
        hint: "销量最高的商品通常是最受欢迎的商品。当前销量最高的商品销量为#{@min_sales}。"
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
        shipping_address: '成都市武侯区天府大道北段1700号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_id: @product&.id, min_sales: @min_sales }
    end
    
    def restore_from_state(data)
      @min_sales = data['min_sales']
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
