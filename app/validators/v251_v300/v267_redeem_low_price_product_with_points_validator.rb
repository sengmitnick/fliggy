# frozen_string_literal: true

require_relative '../base_validator'

# V267: 帮张三使用会员积分+现金兑换热门低价商品（咖啡券，少量积分+现金混合支付）
#
# 任务描述:
#   帮张三使用会员积分+现金兑换热门低价商品（咖啡券类商品），
#   商品价格为少量积分+少量现金的混合支付模式（如50积分+9.9元）。
#   商品为实物配送，需填写收货人信息（张三的地址）。
#
# 业务流程:
#   1. 用户输入：商品类型（咖啡券）、支付方式（积分+现金）、收货人（张三）
#   2. 系统筛选：显示低价咖啡券类商品（价格<15元，需要积分）
#   3. 用户选择：选择合适的商品，确认积分和现金金额
#   4. 填写信息：收货人信息（姓名、电话、地址使用张三的地址）
#   5. 确认支付：核对商品信息、积分金额、现金金额和收货地址
#   6. 完成订单：生成MembershipOrder，扣除用户积分和余额
#   7. 获取凭证：获取订单凭证，等待商品配送
#
# 复杂度分析:
#   1. **混合支付逻辑处理**（中）：需同时验证积分金额和现金金额是否正确
#   2. **积分和余额充足性检查**（低）：验证用户有足够的积分和余额完成兑换
#   3. **商品筛选条件组合**（低）：低价（<15元）、需要积分（price_mileage>0）、咖啡券类商品
#   4. **收货地址信息完整性**（低）：验证收货人姓名、电话、地址与张三的地址信息一致
#
# 评分标准（总分100%）:
#   - 创建了积分兑换订单 (30%) - 基础操作（最高权重）
#   - 商品信息正确（咖啡券类） (15%) - 商品选择准确性
#   - 积分金额正确 (10%) - 支付金额准确性
#   - 现金金额正确 (10%) - 支付金额准确性
#   - 订单数量正确（至少1个） (10%) - 订单数量准确性
#   - 收货人信息正确（张三） (10%) - 收货人信息完整性（姓名、电话）
#   - 订单状态有效 (15%) - 订单可用性
module V251V300
  class V267RedeemLowPriceProductWithPointsValidator < BaseValidator
    self.validator_id = 'v267_redeem_low_price_product_with_points_validator'
    self.task_id = 'e02e9f3a-2b4c-4d1b-8a5f-6c7d8e9f0a1b'
    self.title = '帮张三使用会员积分+现金兑换热门低价商品（咖啡券，少量积分+现金混合支付）'
    self.description = '帮张三使用会员积分+现金兑换热门低价商品（咖啡券类商品），商品价格为少量积分+少量现金的混合支付模式'
    self.timeout_seconds = 300
    
    def prepare
      # 查找低价热门商品（积分商城咖啡券类产品）
      @product = MembershipProduct
        .where(data_version: 0)
        .where('price_cash < ?', 15)  # 低价商品 < 15元
        .where('price_mileage > 0')   # 需要积分
        .where('name LIKE ?', '%咖啡%')  # 咖啡券类
        .order(price_cash: :asc)
        .first
      
      raise "未找到符合条件的低价咖啡券商品" if @product.nil?
      
      @product_name = @product.name
      
      # 检查商品价格
      raise "商品价格设置错误" if @product.price_cash <= 0 && @product.price_mileage <= 0
      
      # 检查用户积分和余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查询张三的地址信息
      @zhangsan_address = user.addresses.find_by!(name: '张三', data_version: 0)
      @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
      @expected_contact_name = @zhangsan_address.name
      @expected_contact_phone = @zhangsan_address.phone
      
      membership = user.membership
      raise "用户无会员记录" if membership.nil?
      
      # 验证用户有足够的积分和余额
      required_points = @product.price_mileage
      required_cash = @product.price_cash
      
      if membership.points < required_points
        raise "用户积分不足。需要: #{required_points}积分，当前: #{membership.points}积分"
      end
      
      if user.balance < required_cash
        raise "用户余额不足。需要: ¥#{required_cash}，当前: ¥#{user.balance}"
      end
      
      {
        task: "请帮张三在积分商城兑换商品：#{@product_name}（#{@product.price_mileage}积分 + #{@product.price_cash}元）",
        requirements: {
          product_name: @product_name,
          price_mileage: @product.price_mileage,
          price_cash: @product.price_cash,
          payment_method: '积分+现金',
          recipient: '张三'
        },
        hint: "该商品需要使用#{@product.price_mileage}积分 + #{@product.price_cash}元进行兑换，收货地址使用张三的地址。"
      }
    end
    
    def verify
      add_assertion "创建了积分兑换订单", weight: 30 do
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
      
      add_assertion "积分金额正确（#{@product.price_mileage}积分）", weight: 10 do
        expect(@order.price_mileage).to eq(@product.price_mileage),
          "积分金额错误。期望: #{@product.price_mileage}积分, 实际: #{@order.price_mileage}积分"
      end
      
      add_assertion "现金金额正确（#{@product.price_cash}元）", weight: 10 do
        expect(@order.price_cash).to eq(@product.price_cash),
          "现金金额错误。期望: #{@product.price_cash}元, 实际: #{@order.price_cash}元"
      end
      
      add_assertion "订单数量正确（至少1个）", weight: 10 do
        expect(@order.quantity).to be >= 1,
          "订单数量错误。期望: ≥1, 实际: #{@order.quantity}"
      end
      
      add_assertion "收货人信息正确（张三）", weight: 10 do
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
      
      # 创建积分兑换订单（使用预查询的地址信息）
      MembershipOrder.create!(
        user: user,
        membership_product: @product,
        quantity: 1,
        price_cash: @product.price_cash,
        price_mileage: @product.price_mileage,
        total_cash: @product.price_cash * 1,
        total_mileage: @product.price_mileage * 1,
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
        zhangsan_address_id: @zhangsan_address&.id
      }
    end
    
    def restore_from_state(data)
      @product_name = data['product_name']
      @product = MembershipProduct.find(data['product_id']) if data['product_id']
      
      # 恢复地址信息
      if data['zhangsan_address_id']
        @zhangsan_address = Address.find(data['zhangsan_address_id'])
        @expected_shipping_address = [@zhangsan_address.province, @zhangsan_address.city, @zhangsan_address.district, @zhangsan_address.detail].compact.join
        @expected_contact_name = @zhangsan_address.name
        @expected_contact_phone = @zhangsan_address.phone
      end
    end
  end
end
