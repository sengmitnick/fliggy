# frozen_string_literal: true

module V251V300
  # V271: 兑换多个不同商品
  #
  # 场景: 用户兑换3个不同的低价商品（咖啡券、奶茶券、代金券）
  # 考点: 订单创建、积分余额扣除、多商品兑换
  class V271RedeemMultipleQuantityValidator < BaseValidator
    self.validator_id = 'v271_redeem_multiple_quantity_validator'
    self.task_id = '6d2fd384-9e74-4e8b-a0fc-cb3fcf871fdd'
    self.title = '帮张三兑换3个不同的低价商品（瑞幸咖啡券 9.9元、蜜雪冰城 5元代金券、肯德基早餐券）'
    self.description = '帮张三兑换3个不同的低价商品（瑞幸咖啡券 9.9元、蜜雪冰城 5元代金券、肯德基早餐券）'
    self.timeout_seconds = 300
    
    def prepare
      @product_names = ['瑞幸咖啡券 9.9元', '蜜雪冰城 5元代金券', '肯德基早餐券']
      @expected_shipping_address = '杭州市西湖区文三路90号'
      
      # 查找3个商品
      @products = @product_names.map do |name|
        product = MembershipProduct.find_by(name: name, data_version: 0)
        raise "未找到商品: #{name}" if product.nil?
        product
      end
      
      # 确保用户有足够的积分和余额（用于兑换3个商品）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      required_points = @products.sum(&:price_mileage)
      required_cash = @products.sum(&:price_cash)
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请在积分商城兑换3个不同的商品：#{@product_names.join('、')}",
        requirements: {
          product_names: @product_names,
          count: 3
        },
        hint: "需要兑换3个不同商品，总计#{required_points}积分 + #{required_cash}元。"
      }
    end
    
    def verify
      add_assertion "创建了3个兑换订单", weight: 20 do
        all_orders = MembershipOrder
          .joins(:membership_product)
          .includes(:membership_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @orders = all_orders
        expect(@orders.size).to eq(3),
          "订单数量错误。期望: 3个订单, 实际: #{@orders.size}个订单"
      end
      
      return if @orders.nil? || @orders.empty?
      
      add_assertion "兑换了3个不同的商品", weight: 25 do
        product_names = @orders.map { |o| o.membership_product.name }.uniq
        expect(product_names.size).to eq(3),
          "商品种类错误。期望: 3种不同商品, 实际: #{product_names.size}种商品（#{product_names.join('、')}）"
      end
      
      add_assertion "包含瑞幸咖啡券 9.9元", weight: 15 do
        product_names = @orders.map { |o| o.membership_product.name }
        expect(product_names).to include('瑞幸咖啡券 9.9元'),
          "未找到瑞幸咖啡券 9.9元订单。已兑换: #{product_names.join('、')}"
      end
      
      add_assertion "包含蜜雪冰城 5元代金券", weight: 15 do
        product_names = @orders.map { |o| o.membership_product.name }
        expect(product_names).to include('蜜雪冰城 5元代金券'),
          "未找到蜜雪冰城 5元代金券订单。已兑换: #{product_names.join('、')}"
      end
      
      add_assertion "包含肯德基早餐券", weight: 15 do
        product_names = @orders.map { |o| o.membership_product.name }
        expect(product_names).to include('肯德基早餐券'),
          "未找到肯德基早餐券订单。已兑换: #{product_names.join('、')}"
      end
      
      add_assertion "收货地址正确", weight: 10 do
        @orders.each do |order|
          expect(order.shipping_address).to eq(@expected_shipping_address),
            "收货地址错误。期望: #{@expected_shipping_address}, 实际: #{order.shipping_address}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 为3个不同商品创建订单
      @products.each do |product|
        MembershipOrder.create!(
          user: user,
          membership_product: product,
          quantity: 1,
          price_cash: product.price_cash,
          price_mileage: product.price_mileage,
          total_cash: product.price_cash * 1,
          total_mileage: product.price_mileage * 1,
          contact_name: user.name,
          contact_phone: user.phone || '13800138000',
          shipping_address: '杭州市西湖区文三路90号',
          status: 'paid',
          data_version: @data_version
        )
      end
    end
    
    private
    
    def execution_state_data
      { 
        product_names: @product_names, 
        product_ids: @products&.map(&:id)
      }
    end
    
    def restore_from_state(data)
      @product_names = data['product_names']
      if data['product_ids']
        @products = data['product_ids'].map { |id| MembershipProduct.find(id) }
      end
    end
  end
end
