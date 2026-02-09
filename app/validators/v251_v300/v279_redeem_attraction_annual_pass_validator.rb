# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例279: 预订景区年卡
#
# 任务描述:
#   用户购买景区年卡，全年无限次入园
#
# 评分标准:
#   - 创建积分兑换年卡订单 (30%)
#   - 商品类型正确（年卡） (25%)
#   - 积分金额正确 (25%)
#   - 订单状态已支付 (20%)
module V251V300
  class V279RedeemAttractionAnnualPassValidator < BaseValidator
    self.validator_id = 'v279_redeem_attraction_annual_pass_validator'
    self.task_id = 'd652bcc5-67fc-4740-b6c9-cc2489749e55'
    self.title = '预订景区年卡'
    self.description = '用户购买景区年卡，全年无限次入园'
    self.timeout_seconds = 300
    
    def prepare
      # 使用积分商城的高价值商品来模拟年卡
      @product_name = '京东E卡 100元'
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
        task: "请在积分商城兑换「#{@product_name}」作为年卡使用，享受长期权益",
        product_name: @product.name,
        price_mileage: @product.price_mileage,
        price_cash: @product.price_cash.to_f,
        hint: "使用积分+现金组合支付，这是一张高价值的年卡商品"
      }
    end
    
    def verify
      add_assertion "创建了积分兑换订单", weight: 30 do
        @order = MembershipOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到积分兑换订单"
      end
      
      return unless @order
      
      add_assertion "兑换的是指定商品（#{@product_name}）", weight: 25 do
        product = @order.membership_product
        expect(product).not_to be_nil, "订单没有关联商品"
        expect(product.name).to eq(@product_name),
          "商品不匹配。期望: #{@product_name}, 实际: #{product.name}"
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 25 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}, 实际: #{@order.price_mileage}"
      end
      
      add_assertion "订单状态为已完成", weight: 20 do
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
        shipping_address: '上海市浦东新区世纪大道1号',
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
