# frozen_string_literal: true

module V251V300
  # V271: 帮张三兑换3个不同的低价商品（瑞幸咖啡券 9.9元、蜜雪冰城 5元代金券、肯德基早餐券）
  #
  # 场景: 用户兑换3个不同的低价商品（咖啡券、奶茶券、代金券）
  # 考点: 订单创建、积分余额扣除、多商品兑换
  #
  # 业务流程:
  #   1. 用户输入：需要兑换3个不同的低价商品（瑞幸咖啡券 9.9元、蜜雪冰城 5元代金券、肯德基早餐券）
  #   2. 系统查询：查找这3个商品的积分和现金价格
  #     - 瑞幸咖啡券 9.9元: 50积分 + 9.9元
  #     - 蜜雪冰城 5元代金券: 10积分 + 4元
  #     - 肯德基早餐券: 50积分 + 15元
  #   3. 提交订单：为每个商品创建一个订单，共3个订单，总计110积分 + 28.9元
  #
  # 复杂度分析:
  #   1. **多商品查询**（中）：需要查找3个不同商品并验证库存
  #   2. **批量订单创建**（中）：需要为3个商品分别创建订单
  #   3. **积分和余额验证**（低）：需要确保用户有足够的积分和现金余额
  #
  # 评分标准（总分100%）:
  #   - 创建3个订单（20分）
  #   - 3个不同商品（25分）
  #   - 包含瑞幸咖啡券（15分）
  #   - 包含蜜雪冰城代金券（15分）
  #   - 包含肯德基早餐券（15分）
  #   - 收货地址正确（10分）
  class V271RedeemMultipleQuantityValidator < BaseValidator
    self.validator_id = 'v271_redeem_multiple_quantity_validator'
    self.task_id = '6d2fd384-9e74-4e8b-a0fc-cb3fcf871fdd'
    self.title = '帮张三兑换3个不同的低价商品（瑞幸咖啡券 9.9元、蜜雪冰城 5元代金券、肯德基早餐券）'
    self.description = '帮张三兑换3个不同的低价商品（瑞幸咖啡券 9.9元 50积分+9.9元、蜜雪冰城 5元代金券 10积分+4元、肯德基早餐券 50积分+15元），总计110积分+28.9元'
    self.timeout_seconds = 300
    
    def prepare
      @product_names = ['瑞幸咖啡券 9.9元', '蜜雪冰城 5元代金券', '肯德基早餐券']
      
      # 查找张三的收货地址
      zhangsan = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_address = zhangsan.addresses.where(data_version: 0).first!
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      
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
          count: 3,
          total_points: required_points,
          total_cash: required_cash
        },
        hint: "需要兑换3个不同商品（瑞幸咖啡券 9.9元 50积分+9.9元、蜜雪冰城 5元代金券 10积分+4元、肯德基早餐券 50积分+15元），总计#{required_points}积分 + #{required_cash}元。"
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
          shipping_address: @expected_shipping_address,
          status: 'paid',
          data_version: @data_version
        )
      end
    end
    
    private
    
    def execution_state_data
      { 
        product_names: @product_names, 
        product_ids: @products&.map(&:id),
        zhangsan_address_id: @zhangsan_address&.id,
        expected_shipping_address: @expected_shipping_address
      }
    end
    
    def restore_from_state(data)
      @product_names = data['product_names']
      @expected_shipping_address = data['expected_shipping_address']
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
      end
      if data['product_ids']
        @products = data['product_ids'].map { |id| MembershipProduct.find(id) }
      end
    end
  end
end
