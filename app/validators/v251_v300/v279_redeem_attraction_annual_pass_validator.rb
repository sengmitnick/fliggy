# frozen_string_literal: true

require_relative '../base_validator'

# V279: 帮李四使用积分+现金兑换天猫超市卡 200元（积分+现金混合支付）
#
# 任务描述:
#   帮李四使用会员积分+现金兑换天猫超市卡 200元，
#   商品价格为积分+现金的混合支付模式。
#   商品为实物配送，需填写收货人信息（李四的地址）。
#
# 业务流程（7个关键步骤）:
#   1. 用户输入：商品名称（天猫超市卡 200元）、支付方式（积分+现金）、收货人（李四）
#   2. 系统筛选：查找天猫超市卡 200元商品（需要积分+现金）
#   3. 用户选择：选择天猫超市卡 200元，确认积分和现金金额
#   4. 填写信息：收货人信息（姓名、电话、地址使用李四的地址）
#   5. 确认支付：核对商品信息、积分金额、现金金额和收货地址
#   6. 完成订单：生成MembershipOrder，扣除用户积分和余额
#   7. 获取凭证：获取订单凭证，等待商品配送
#
# 复杂度分析（4个关键点）:
#   1. **混合支付逻辑处理**（中）：需同时验证积分金额和现金金额是否正确
#   2. **积分和余额充足性检查**（低）：验证用户有足够的积分和余额完成兑换
#   3. **商品信息准确性**（低）：验证天猫超市卡商品信息（名称、价格）准确无误
#   4. **收货地址信息完整性**（低）：验证收货人姓名、电话、地址与李四的地址信息一致
#
# 评分标准（6项，总计100分）:
#   - 创建了积分兑换订单 (25%) - 基础操作（最高权重）
#   - 商品信息正确（天猫超市卡 200元） (15%) - 商品选择准确性
#   - 积分金额正确 (15%) - 支付金额准确性
#   - 现金金额正确 (15%) - 支付金额准确性
#   - 收货人信息正确（李四） (15%) - 收货人信息完整性（姓名、电话）
#   - 订单状态有效 (15%) - 订单可用性
module V251V300
  class V279RedeemAttractionAnnualPassValidator < BaseValidator
    self.validator_id = 'v279_redeem_attraction_annual_pass_validator'
    self.task_id = 'd652bcc5-67fc-4740-b6c9-cc2489749e55'
    self.title = '帮李四使用积分+现金兑换天猫超市卡 200元'
    self.description = '帮李四使用会员积分+现金兑换天猫超市卡 200元，商品为实物配送，需填写李四的收货地址'
    self.timeout_seconds = 300
    
    def prepare
      # 查找天猫超市卡商品
      @product_name = '天猫超市卡 200元'
      @product = MembershipProduct.find_by!(name: @product_name, data_version: 0)
      
      raise "商品价格设置错误" if @product.price_cash <= 0 && @product.price_mileage <= 0
      
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
          payment_method: '积分+现金',
          recipient: '李四'
        },
        hint: "该商品需要使用#{@product.price_mileage}积分 + #{@product.price_cash}元进行兑换，收货地址使用李四的地址。"
      }
    end
    
    def verify
      add_assertion "创建了积分兑换订单", weight: 25 do
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
      
      add_assertion "商品信息正确（#{@product_name}）", weight: 15 do
        expect(@order.membership_product.name).to eq(@product_name),
          "商品名称错误。期望: #{@product_name}, 实际: #{@order.membership_product.name}"
      end
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 15 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "现金金额正确（#{@product.price_cash}元）", weight: 15 do
        expect(@order.price_cash).to eq(@product.price_cash),
          "现金金额错误。期望: #{@product.price_cash}元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "收货人信息正确（李四）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "收货人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        valid_statuses = ['pending', 'paid', 'shipping', 'completed']
        expect(@order.status).to be_in(valid_statuses),
          "订单状态无效。期望: #{valid_statuses.join('/')}, 实际: #{@order.status}"
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
