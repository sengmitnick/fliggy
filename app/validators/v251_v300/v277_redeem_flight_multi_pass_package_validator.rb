# frozen_string_literal: true

require_relative '../base_validator'

module V251V300
  # V277: 帮张三购买10次经济舱套餐，享受折扣价格和灵活使用
  #
  # 场景: 用户在积分商城兑换机票次卡套餐，享受批量购买折扣
  # 考点: 机票次卡兑换、套餐商品购买
  #
  # 业务流程:
  #   1. 用户输入：需要在积分商城购买10次经济舱套餐作为机票次卡
  #   2. 商品查找：查找「机票次卡 10次经济舱套餐」商品
  #   3. 积分验证：确认用户积分和余额充足
  #   4. 提交订单：创建兑换订单并支付
  #
  # 复杂度分析:
  #   1. **商品查找**（低）：按商品名称精确查找机票次卡套餐
  #   2. **积分验证**（低）：验证用户积分和余额是否充足
  #   3. **订单创建**（低）：创建单个兑换订单
  #
  # 评分标准（总分100%）:
  #   - 创建了积分兑换订单 (25%)
  #   - 兑换的是指定商品（机票次卡 10次经济舱套餐） (40%)
  #   - 积分金额正确 (20%)
  #   - 订单已支付 (15%)
  class V277RedeemFlightMultiPassPackageValidator < BaseValidator
    self.validator_id = 'v277_redeem_flight_multi_pass_package_validator'
    self.task_id = '8b0d78b3-b4ce-4e39-963d-aa0e5c455398'
    self.title = '帮张三购买10次经济舱套餐，享受折扣价格和灵活使用'
    self.description = '帮张三购买10次经济舱套餐，享受折扣价格和灵活使用'
    self.timeout_seconds = 300
    
    def prepare
      # 使用积分商城的机票次卡商品
      @product_name = '机票次卡 10次经济舱套餐'
      @product = MembershipProduct.find_by!(name: @product_name, data_version: 0)
      
      # 查找张三的收货地址
      zhangsan = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_address = zhangsan.addresses.where(data_version: 0).first!
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      
      # 确保用户有足够积分和余额
      membership = zhangsan.membership || zhangsan.create_membership!(points: 0, level: 'gold', data_version: 0)
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if zhangsan.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{zhangsan.balance}"
      end
      
      {
        task: "请在积分商城兑换「#{@product_name}」作为机票次卡使用",
        requirements: {
          product_name: @product.name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash.to_f,
          rating: @product.rating,
          sales_count: @product.sales_count,
          category: @product.category
        },
        hint: "机票次卡套餐支持灵活使用，享受批量购买折扣。使用积分+现金组合支付。"
      }
    end
    
    def verify
      add_assertion "创建了积分兑换订单", weight: 25 do
        @order = MembershipOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到积分兑换订单"
      end
      
      return unless @order
      
      add_assertion "兑换的是指定商品（#{@product_name}）", weight: 40 do
        product = @order.membership_product
        expect(product).not_to be_nil, "订单没有关联商品"
        expect(product.name).to eq(@product_name),
          "商品不匹配。期望: #{@product_name}, 实际: #{product.name}"
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 20 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}, 实际: #{@order.price_mileage}"
      end
      
      add_assertion "订单已支付", weight: 15 do
        expect(@order.status).to eq('completed').or(eq('paid')),
          "订单状态错误。期望: completed/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership
      product = MembershipProduct.find_by!(name: @product_name, data_version: 0)
      
      MembershipOrder.create!(
        user_id: user.id,
        membership_product_id: product.id,
        quantity: 1,
        price_mileage: product.price_mileage,
        price_cash: product.price_cash,
        total_mileage: product.price_mileage,
        total_cash: product.price_cash,
        contact_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
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
        zhangsan_address_id: @zhangsan_address&.id,
        expected_shipping_address: @expected_shipping_address
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @expected_shipping_address = data['expected_shipping_address']
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
      end
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
