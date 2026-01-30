# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例098: 会员商城购买商品（里程+现金混合支付）
#
# 任务描述:
#   购买会员商城热门商品，使用5000里程+200元现金的混合支付方式
#
# 评分标准:
#   - TODO: 定义评分标准
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v098_membership_mall_purchase_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V098MembershipMallPurchaseValidator < BaseValidator
  self.validator_id = 'v098_membership_mall_purchase_validator'
  self.task_id = 'd00512b3-662a-4fb1-bd9f-30b245119d85'
  self.title = '会员商城购买商品（里程+现金混合支付）'
  self.description = '购买会员商城热门商品，使用5000里程+200元现金的混合支付方式'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  #
  # 返回任务信息给 Agent（必须包含 task 字段）
  #
  # Example:
  #   def prepare
  #     @city = '深圳'
  #     @budget = 500
  #     
  #     {
  #       task: "请预订#{@city}的酒店，预算≤#{@budget}元",
  #       city: @city,
  #       budget: @budget,
  #       hint: "系统中有多家酒店可选，请选择性价比最高的"
  #     }
  #   end
  def prepare
    @category = 'popular'
    @required_mileage = 5000
    @required_cash = 200
    @quantity = 1
    @shipping_province = '北京市'
    @shipping_city = '朝阳区'
    @shipping_address = '朝阳区建外SOHO西区12号楼'
    
    # 查找符合条件的商品（热门分类，同时需要里程和现金）
    @qualified_products = MembershipProduct.where(data_version: 0)
                                           .where(category: @category)
                                           .where('price_mileage >= ? AND price_cash >= ?', 1, 1)
                                           .available
    
    # 查找最符合要求的商品（里程价格接近5000，现金价格接近200）
    @target_product = @qualified_products.min_by do |p|
      (p.price_mileage - @required_mileage).abs + (p.price_cash - @required_cash).abs * 10
    end
    
    {
      task: "请在会员商城购买1件热门商品，使用约#{@required_mileage}里程+#{@required_cash}元现金的混合支付方式，配送地址填写北京市朝阳区",
      requirements: {
        category: 'popular',
        category_description: '热门商品分类',
        payment_method: 'hybrid',
        payment_description: '里程+现金混合支付',
        mileage_budget: @required_mileage,
        cash_budget: @required_cash,
        quantity: @quantity,
        shipping_province: @shipping_province,
        shipping_city: @shipping_city
      },
      hint: "会员商城有多款商品可选，请选择同时需要里程和现金的热门商品，价格接近#{@required_mileage}里程+#{@required_cash}元",
      statistics: {
        total_products: MembershipProduct.where(data_version: 0).count,
        qualified_products: @qualified_products.count
      }
    }
  end
  
  # 验证阶段：检查任务是否完成
  #
  # 使用 add_assertion 添加断言（必须指定 weight 权重，总和为 100）
  def verify
    add_assertion "订单已创建", weight: 25 do
      all_orders = MembershipOrder.joins(:membership_product)
                                   .where(membership_products: { category: @category })
                                   .where(data_version: @data_version)
                                   .order(created_at: :desc)
                                   .to_a
      
      @orders = all_orders.select do |o|
        o.price_mileage > 0 && o.price_cash > 0
      end
      
      expect(@orders).not_to be_empty, "未找到任何会员商城订单"
      @order = @orders.first
    end
    
    return if @orders.nil? || @orders.empty?
    
    add_assertion "商品分类正确（热门商品）", weight: 15 do
      expect(@order.membership_product.category).to eq(@category),
        "商品分类错误。期望: #{@category}（热门商品），实际: #{@order.membership_product.category}"
    end
    
    add_assertion "使用了混合支付方式（里程+现金）", weight: 20 do
      expect(@order.price_mileage).to be > 0,
        "未使用里程支付。实际里程: #{@order.price_mileage}"
      expect(@order.price_cash).to be > 0,
        "未使用现金支付。实际现金: #{@order.price_cash}元"
    end
    
    add_assertion "支付金额合理（里程约5000，现金约200元）", weight: 20 do
      mileage_diff = (@order.price_mileage - @required_mileage).abs
      cash_diff = (@order.price_cash - @required_cash).abs
      
      expect(mileage_diff).to be <= 2000,
        "里程金额偏差过大。期望约#{@required_mileage}里程，实际: #{@order.price_mileage}里程（偏差#{mileage_diff}）"
      expect(cash_diff).to be <= 100,
        "现金金额偏差过大。期望约#{@required_cash}元，实际: #{@order.price_cash}元（偏差#{cash_diff}元）"
    end
    
    add_assertion "配送信息完整（北京市朝阳区）", weight: 20 do
      errors = []
      errors << "缺少联系人姓名" if @order.contact_name.blank?
      errors << "缺少联系电话" if @order.contact_phone.blank?
      errors << "缺少配送地址" if @order.shipping_address.blank?
      
      unless @order.contact_phone.blank? || @order.contact_phone.match?(/\A1[3-9]\d{9}\z/)
        errors << "联系电话格式不正确（应为11位手机号）"
      end
      
      # 检查地址是否包含朝阳区（北京市的一个区）
      unless @order.shipping_address.to_s.include?('朝阳区')
        errors << "配送地址应包含朝阳区"
      end
      
      expect(errors).to be_empty,
        "配送信息存在问题: #{errors.join('; ')}"
    end
  end
  
  # 模拟 AI Agent 操作
  #
  # 此方法模拟 AI Agent 如何完成任务（用于自动化测试）
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 查找最符合要求的热门商品（同时需要里程和现金，价格接近目标）
    target_product = MembershipProduct.where(data_version: 0)
                                      .where(category: @category)
                                      .where('price_mileage >= ? AND price_cash >= ?', 1, 1)
                                      .available
                                      .min_by do |p|
      (p.price_mileage - @required_mileage).abs + (p.price_cash - @required_cash).abs * 10
    end
    
    raise "未找到符合条件的会员商城商品" unless target_product
    
    # 创建会员商城订单
    MembershipOrder.create!(
      user_id: user.id,
      membership_product_id: target_product.id,
      quantity: @quantity,
      price_cash: target_product.price_cash,
      price_mileage: target_product.price_mileage,
      total_cash: target_product.price_cash * @quantity,
      total_mileage: target_product.price_mileage * @quantity,
      contact_name: '张三',
      contact_phone: '13800138000',
      shipping_address: @shipping_address,
      status: 'pending',
      data_version: @data_version
    )
  end
  
  private
  
  # 保存执行状态数据（用于跨请求恢复状态）
  #
  # 返回需要持久化的实例变量数据
  def execution_state_data
    {
      category: @category,
      required_mileage: @required_mileage,
      required_cash: @required_cash,
      quantity: @quantity,
      shipping_province: @shipping_province,
      shipping_city: @shipping_city,
      shipping_address: @shipping_address
    }
  end
  
  # 从状态恢复实例变量（用于跨请求恢复状态）
  #
  # 从持久化数据恢复实例变量
  def restore_from_state(data)
    @category = data['category']
    @required_mileage = data['required_mileage']
    @required_cash = data['required_cash']
    @quantity = data['quantity']
    @shipping_province = data['shipping_province']
    @shipping_city = data['shipping_city']
    @shipping_address = data['shipping_address']
    
    @qualified_products = MembershipProduct.where(data_version: 0)
                                           .where(category: @category)
                                           .where('price_mileage >= ? AND price_cash >= ?', 1, 1)
                                           .available
  end
end
