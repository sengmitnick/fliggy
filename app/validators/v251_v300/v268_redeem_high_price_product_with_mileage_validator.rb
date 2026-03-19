# frozen_string_literal: true

require_relative '../base_validator'

module V251V300
  # V268: 帮李四使用大量积分+现金兑换京东E卡100元（大额积分+少量现金混合支付）
  #
  # 任务描述:
  #   帮李四使用大量积分+少量现金兑换京东E卡100元，
  #   商品价格为大额积分+少量现金的混合支付模式（5000积分+10元）。
  #   商品为实物配送，需填写收货人信息（李四的地址）。
  #
  # 业务流程:
  #   1. 用户输入：商品名称（京东E卡100元）、支付方式（大量积分+现金）、收货人（李四）
  #   2. 系统筛选：查找京东E卡100元商品（需要5000积分+10元）
  #   3. 用户选择：选择京东E卡100元，确认积分和现金金额
  #   4. 填写信息：收货人信息（姓名、电话、地址使用李四的地址）
  #   5. 确认支付：核对商品信息、5000积分、10元现金和收货地址
  #   6. 完成订单：生成MembershipOrder，扣除用户积分和余额
  #   7. 获取凭证：获取订单凭证，等待商品配送
  #
  # 复杂度分析:
  #   1. **大额积分扣除逻辑**（中）：需验证用户有足够的积分（5000积分）完成兑换
  #   2. **混合支付金额验证**（低）：需同时验证5000积分和10元现金金额是否正确
  #   3. **商品信息准确性**（低）：验证京东E卡100元商品信息（名称、价格）准确无误
  #   4. **收货地址信息完整性**（低）：验证收货人姓名、电话、地址与李四的地址信息一致
  #
  # 评分标准（总分100%）:
  #   - 创建了兑换订单 (30%) - 基础操作（最高权重）
  #   - 商品正确（京东E卡100元） (15%) - 商品选择准确性
  #   - 积分金额正确（5000积分） (15%) - 支付金额准确性（大额积分验证）
  #   - 现金金额正确（10元） (15%) - 支付金额准确性
  #   - 收货人信息正确（李四） (10%) - 收货人信息完整性（姓名、电话）
  #   - 订单状态有效 (15%) - 订单可用性
  class V268RedeemHighPriceProductWithMileageValidator < BaseValidator
    self.validator_id = 'v268_redeem_high_price_product_with_mileage_validator'
    self.task_id = '5cbb17c4-ca76-4bca-b9ef-e5b0253e6d97'
    self.title = '帮李四使用大量积分+现金兑换京东E卡100元（大额积分+少量现金混合支付）'
    self.description = '帮李四使用5000积分+10元现金兑换京东E卡100元，需要大额积分才能兑换'
    self.timeout_seconds = 300
    
    def prepare
      @product_name = '京东E卡 100元'
      
      # 查找商品
      @product = MembershipProduct.find_by(name: @product_name, data_version: 0)
      raise "未找到商品: #{@product_name}" if @product.nil?
      
      # 验证用户有足够的积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查询李四的地址信息
      @lisi_address = user.addresses.find_by!(name: '李四', data_version: 0)
      @expected_shipping_address = [@lisi_address.province, @lisi_address.city, @lisi_address.district, @lisi_address.detail].compact.join
      @expected_contact_name = @lisi_address.name
      @expected_contact_phone = @lisi_address.phone
      
      membership = user.membership
      raise "用户无会员记录" if membership.nil?
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      # 验证积分和余额是否足够
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{user.balance}"
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
        @expected_shipping_address = [@lisi_address.province, @lisi_address.city, @lisi_address.district, @lisi_address.detail].compact.join
        @expected_contact_name = @lisi_address.name
        @expected_contact_phone = @lisi_address.phone
      end
    end
  end
end
