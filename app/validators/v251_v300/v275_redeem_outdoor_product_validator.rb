# frozen_string_literal: true

module V251V300
  # V275: 兑换户外运动类商品
  #
  # 场景: 用户在户外运动分类中选择商品兑换
  # 考点: 分类筛选、户外用品兑换
  class V275RedeemOutdoorProductValidator < BaseValidator
    self.validator_id = 'v275_redeem_outdoor_product_validator'
    self.task_id = 'a5aef388-200e-4f74-9c41-eecdd50281b9'
    self.title = '帮张三在积分商城的「户外运动」分类中选择商品兑换'
    self.description = '帮张三在积分商城的「户外运动」分类中选择商品兑换'
    self.timeout_seconds = 300
    
    def prepare
      @category = 'outdoor'
      @category_name = '户外运动'
      @expected_shipping_address = '南京市玄武区中山路1号'
      
      # 查找户外运动分类商品
      @outdoor_products = MembershipProduct
        .where(category: @category, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
      
      raise "未找到#{@category_name}分类商品" if @outdoor_products.empty?
      
      # 选择第一个商品
      @product = @outdoor_products.first
      @product_name = @product.name
      
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
        task: "请在积分商城的「#{@category_name}」分类中选择一个商品进行兑换",
        requirements: {
          category: @category_name,
          available_products: @outdoor_products.map(&:name)
        },
        hint: "#{@category_name}分类包含登山、露营、徒步等户外装备。"
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
      
      add_assertion "商品属于#{@category_name}分类", weight: 35 do
        product = @order.membership_product
        expect(product.category).to eq(@category),
          "商品分类错误。期望: #{@category}(#{@category_name}), 实际: #{product.category}(#{product.category_name})"
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
        shipping_address: '南京市玄武区中山路1号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_id: @product&.id, category: @category }
    end
    
    def restore_from_state(data)
      @category = data['category']
      @category_name = '户外运动'
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      @outdoor_products = MembershipProduct
        .where(category: @category, data_version: 0)
        .order(sales_count: :desc)
        .limit(5)
        .to_a
    end
  end
end
