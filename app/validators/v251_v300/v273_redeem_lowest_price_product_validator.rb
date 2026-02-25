# frozen_string_literal: true

module V251V300
  # V273: 按价格排序选择低价商品
  #
  # 场景: 用户按价格升序排序，选择价格最低的商品兑换
  # 考点: 价格排序、性价比选择
  class V273RedeemLowestPriceProductValidator < BaseValidator
    self.validator_id = 'v273_redeem_lowest_price_product_validator'
    self.task_id = '4df2344f-f74d-41e8-9bf7-0b2a2e16c295'
    self.title = '帮张三在积分商城按价格升序排序，选择价格最低的商品兑换'
    self.description = '帮张三在积分商城按价格升序排序，选择价格最低的商品兑换'
    self.timeout_seconds = 300
    
    def prepare
      @expected_shipping_address = '武汉市江汉区解放大道688号'
      
      # 查找价格最低的商品（现金+积分总价值）
      @low_price_products = MembershipProduct
        .where(data_version: 0)
        .where('price_cash > 0 OR price_mileage > 0')
        .order(Arel.sql('COALESCE(price_cash, 0) + COALESCE(price_mileage, 0) / 100.0 ASC'))
        .limit(5)
        .to_a
      
      raise "未找到商品" if @low_price_products.empty?
      
      @product = @low_price_products.first
      @product_name = @product.name
      @max_price = @product.price_cash + (@product.price_mileage / 100.0) # 积分按1:100折算
      
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
        task: "请在积分商城按价格升序排序，选择价格最低的商品进行兑换",
        requirements: {
          sort_by: 'price',
          order: 'asc',
          low_price_products: @low_price_products.map { |p| { name: p.name, price: p.price_display } }
        },
        hint: "价格最低的商品适合用少量积分/现金进行兑换。"
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
      
      add_assertion "兑换的是价格最低的5个商品之一", weight: 35 do
        product = @order.membership_product
        low_price_names = @low_price_products.map(&:name)
        
        expect(low_price_names).to include(product.name),
          "商品不在价格最低的5个商品中。已兑换: #{product.name}, 价格最低5个: #{low_price_names.join('、')}"
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
        shipping_address: '武汉市江汉区解放大道688号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_id: @product&.id, max_price: @max_price }
    end
    
    def restore_from_state(data)
      @max_price = data['max_price'].to_f
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      @product_name = @product&.name
      
      @low_price_products = MembershipProduct
        .where(data_version: 0)
        .where('price_cash > 0 OR price_mileage > 0')
        .order(Arel.sql('COALESCE(price_cash, 0) + COALESCE(price_mileage, 0) / 100.0 ASC'))
        .limit(5)
        .to_a
    end
  end
end
