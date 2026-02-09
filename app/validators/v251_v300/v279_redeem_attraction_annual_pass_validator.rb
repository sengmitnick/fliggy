# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例279: 兑换天猫超市卡
#
# 任务描述:
#   用户兑换天猫超市卡，需要填写收货地址
#
# 评分标准:
#   - 创建积分兑换订单 (25%)
#   - 商品正确（天猫超市卡） (30%)
#   - 积分金额正确 (20%)
#   - 填写了收货地址 (15%)
#   - 订单状态已支付 (10%)
module V251V300
  class V279RedeemAttractionAnnualPassValidator < BaseValidator
    self.validator_id = 'v279_redeem_attraction_annual_pass_validator'
    self.task_id = 'd652bcc5-67fc-4740-b6c9-cc2489749e55'
    self.title = '给李四兑换天猫超市卡 200元'
    self.description = '帮李四兑换天猫超市卡，需要填写收货地址'
    self.timeout_seconds = 300
    
    def prepare
      # 兑换天猫超市卡
      @product_name = '天猫超市卡 200元'
      @product = MembershipProduct.find_by!(name: @product_name, data_version: 0)
      
      # 确保用户有足够积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      membership = user.membership || user.create_membership!(points: 0, level: 'gold', data_version: 0)
      
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请在积分商城为李四兑换「#{@product_name}」，需要填写李四的收货地址",
        product_name: @product.name,
        price_mileage: @product.price_mileage,
        price_cash: @product.price_cash.to_f,
        hint: "使用积分+现金组合支付，需要填写收货地址"
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
      
      add_assertion "兑换的是指定商品（#{@product_name}）", weight: 30 do
        product = @order.membership_product
        expect(product).not_to be_nil, "订单没有关联商品"
        expect(product.name).to eq(@product_name),
          "商品不匹配。期望: #{@product_name}, 实际: #{product.name}"
      end
      
      add_assertion "填写了收货地址（李四）", weight: 15 do
        expect(@order.shipping_address).not_to be_nil, "未填写收货地址"
        expect(@order.shipping_address).to include('李四').or(include('上海')),
          "收货地址不匹配。期望包含: 李四或上海, 实际: #{@order.shipping_address}"
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 20 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}, 实际: #{@order.price_mileage}"
      end
      
      add_assertion "订单已支付", weight: 10 do
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
        contact_name: '李四',
        contact_phone: '13900139000',
        shipping_address: '上海市浦东新区陆家嘴环路1000号',
        status: 'completed',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        product_name: @product_name,
        product_id: @product&.id
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
    end
  end
end
