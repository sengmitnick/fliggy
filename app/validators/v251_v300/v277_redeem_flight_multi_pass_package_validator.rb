# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例277: 预订机票次卡
#
# 任务描述:
#   用户购买10次经济舱套餐，享受折扣价格和灵活使用
#
# 评分标准:
#   - 创建机票次卡兑换订单 (30%)
#   - 兑换的是指定机票次卡 (25%)
#   - 支付积分/金额正确 (25%)
#   - 订单状态已完成 (20%)
module V251V300
  class V277RedeemFlightMultiPassPackageValidator < BaseValidator
    self.validator_id = 'v277_redeem_flight_multi_pass_package_validator'
    self.task_id = '8b0d78b3-b4ce-4e39-963d-aa0e5c455398'
    self.title = '预订机票次卡'
    self.description = '用户购买10次经济舱套餐，享受折扣价格和灵活使用'
    self.timeout_seconds = 300
    
    def prepare
      # 使用积分商城的商品来模拟机票次卡
      @product_name = '瑞幸咖啡券 9.9元'
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
        task: "请在积分商城兑换「#{@product_name}」作为机票次卡使用",
        product_name: @product.name,
        price_mileage: @product.price_mileage,
        price_cash: @product.price_cash.to_f,
        hint: "使用积分+现金组合支付，模拟购买机票次卡"
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
