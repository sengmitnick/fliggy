# frozen_string_literal: true

module V251V300
  # V268: 给李四使用大量积分兑换高价商品
  #
  # 场景: 用户使用大量积分+现金兑换高价商品（如京东E卡100元）
  # 考点: 高价商品兑换、积分消耗验证
  class V268RedeemHighPriceProductWithMileageValidator < BaseValidator
    self.validator_id = 'v268_redeem_high_price_product_with_mileage_validator'
    self.task_id = '5cbb17c4-ca76-4bca-b9ef-e5b0253e6d97'
    self.title = '给李四使用大量积分兑换高价商品'
    self.description = '帮李四使用大量积分+现金兑换高价商品（如京东E卡）'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '京东E卡 100元'
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 确保用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查询李四的地址信息
      @lisi_address = user.addresses.find_by!(name: '李四', data_version: 0)
      @expected_shipping_address = "#{@lisi_address.province}#{@lisi_address.city}#{@lisi_address.district}#{@lisi_address.detail}"
      @expected_contact_name = @lisi_address.name
      @expected_contact_phone = @lisi_address.phone
      
      membership = user.membership
      raise "用户无会员记录" if membership.nil?
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        membership.update!(points: required_points + 500)
      end
      
      if user.balance < required_cash
        user.update!(balance: required_cash + 200)
      end
      
      {
        task: "请帮李四在积分商城兑换：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          recipient: '李四'
        },
        hint: "该商品需要大量积分（#{@product.price_mileage}积分）才能兑换，收货地址使用李四的地址。"
      }
    end
    
    def verify
      add_assertion "创建了兑换订单", weight: 30 do
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
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 15 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "现金金额正确（#{@product.price_cash}元）", weight: 15 do
        expect(@order.price_cash).to eq(@product.price_cash),
          "现金金额错误。期望: #{@product.price_cash}元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "收货人信息正确（李四）", weight: 10 do
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
        product_name: @product_name, 
        product_id: @product&.id,
        lisi_address_id: @lisi_address&.id
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      
      # 恢复地址信息
      if data['lisi_address_id']
        @lisi_address = Address.find(data['lisi_address_id'])
        @expected_shipping_address = "#{@lisi_address.province}#{@lisi_address.city}#{@lisi_address.district}#{@lisi_address.detail}"
        @expected_contact_name = @lisi_address.name
        @expected_contact_phone = @lisi_address.phone
      end
    end
  end
end
