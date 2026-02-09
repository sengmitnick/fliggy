# frozen_string_literal: true

module V251V300
  # V271: 批量兑换多件商品
  #
  # 场景: 用户一次性兑换多件同一商品（如3张咖啡券）
  # 考点: 数量计算、总价计算
  class V271RedeemMultipleQuantityValidator < BaseValidator
    self.validator_id = 'v271_redeem_multiple_quantity_validator'
    self.task_id = '6d2fd384-9e74-4e8b-a0fc-cb3fcf871fdd'
    self.title = '批量兑换多件商品'
    self.description = '用户一次性兑换多件同一商品（如3张咖啡券）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '蜜雪冰城 5元代金券'
      @quantity = 3
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      
      required_points = @product.price_mileage * @quantity
      required_cash = @product.price_cash * @quantity
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请在积分商城兑换#{@quantity}张#{@product_name}",
        requirements: {
          product_name: @product_name,
          quantity: @quantity,
          total_mileage: @product.price_mileage * @quantity,
          total_cash: @product.price_cash * @quantity
        },
        hint: "需要兑换#{@quantity}张券，总计#{@product.price_mileage * @quantity}积分 + #{@product.price_cash * @quantity}元。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 25 do
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
        expect(@order.membership_product.name).to eq(@product_name)
      end
      
      add_assertion "数量正确（#{@quantity}件）", weight: 20 do
        expect(@order.quantity).to eq(@quantity),
          "数量错误。期望: #{@quantity}件, 实际: #{@order.quantity}件"
      end
      
      add_assertion "总积分正确（#{@product.price_mileage * @quantity}积分）", weight: 20 do
        expected_total = @product.price_mileage * @quantity
        expect(@order.total_mileage).to eq(expected_total),
          "总积分错误。期望: #{expected_total}积分, 实际: #{@order.total_mileage}积分"
      end
      
      add_assertion "总金额正确（#{@product.price_cash * @quantity}元）", weight: 20 do
        expected_total = @product.price_cash * @quantity
        expect(@order.total_cash).to eq(expected_total),
          "总金额错误。期望: #{expected_total}元, 实际: #{@order.total_cash}元"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      MembershipOrder.create!(
        user: user,
        membership_product: @product,
        quantity: @quantity,
        price_cash: @product.price_cash,
        price_mileage: @product.price_mileage,
        total_cash: @product.price_cash * @quantity,
        total_mileage: @product.price_mileage * @quantity,
        contact_name: user.name,
        contact_phone: user.phone || '13800138000',
        shipping_address: '杭州市西湖区文三路90号',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      { product_name: @product_name, product_id: @product&.id, quantity: @quantity }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @quantity = data['quantity']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
