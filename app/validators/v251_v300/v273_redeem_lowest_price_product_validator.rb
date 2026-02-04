# frozen_string_literal: true

module V251V300
  # V273: 按价格排序选择低价商品
  #
  # 场景: 用户按价格升序排序，选择价格最低的商品兑换
  # 考点: 价格排序、性价比选择
  class V273RedeemLowestPriceProductValidator < BaseValidator
    self.validator_id = 'v273_redeem_lowest_price_product_validator'
    self.task_id = 'k68k5l9g-8h0i-0j7k-4g1l-2i3j4k5l6m7h'
    self.title = '按价格排序选择低价商品'
    self.description = '用户按价格升序排序，选择价格最低的商品兑换'
    self.timeout_seconds = 300
    
    def prepare
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
        membership.update!(points: @product.price_mileage + 500)
      end
      
      if user.balance < @product.price_cash
        user.update!(balance: @product.price_cash + 100)
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
      
      add_assertion "兑换的是低价商品", weight: 35 do
        product = @order.membership_product
        total_price = product.price_cash + (product.price_mileage / 100.0)
        max_limit = @max_price * 2
        expect(total_price).to be <= max_limit,
          "商品价格过高，不是低价商品。价格: #{product.price_display}, 最高限制: #{max_limit.round(2)}元等价"
      end
      
      add_assertion "商品有效", weight: 15 do
        product = @order.membership_product
        expect(product.name).not_to be_empty
        expect(product.price_cash > 0 || product.price_mileage > 0).to be_truthy
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
