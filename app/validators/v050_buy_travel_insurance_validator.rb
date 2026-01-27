# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例50: 购买境内旅游保险（7天，1人，最便宜产品）
# 
# 任务描述:
#   Agent 需要在系统中搜索境内旅游保险产品，
#   选择7天保障期最便宜的产品并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品（domestic类型）
#   2. 需要计算7天的总价（price_per_day × 7）
#   3. 需要对比多个保险公司的价格
#   4. 需要选择总价最低的产品
#   5. 需要填写保险信息（保障时间、被保险人等）
#   ❌ 不能一次性提供：需要先搜索→计算价格→对比→购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境内旅游）(15分)
#   - 保障天数正确（7天）(15分)
#   - 选择了最便宜的产品 (30分)
#   - 订单总价计算正确 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v050_buy_travel_insurance_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V050BuyTravelInsuranceValidator < BaseValidator
  self.validator_id = 'v050_buy_travel_insurance_validator'
  self.title = '购买境内旅游保险（7天，1人，最便宜产品）'
  self.description = '需要搜索境内旅游保险产品，选择7天保障期最便宜的产品并成功创建订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @product_type = 'domestic'
    @days = 7
    @quantity = 1
    @start_date = Date.current + 3.days  # 3天后开始
    @end_date = @start_date + @days - 1  # 保障结束日期
    
    # 查找境内旅游保险产品（注意：查询基线数据 data_version=0）
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
    
    # 返回给 Agent 的任务信息
    {
      task: "请购买境内旅游保险（保障期#{@days}天，#{@quantity}人），选择最便宜的产品",
      product_type: "境内旅游",
      days: @days,
      quantity: @quantity,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      hint: "系统中有多家保险公司提供该产品，请根据每日单价计算#{@days}天总价后选择最便宜的",
      available_products_count: @available_products.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @insurance_order = InsuranceOrder.order(created_at: :desc).first
      expect(@insurance_order).not_to be_nil, "未找到任何保险订单记录"
    end
    
    return unless @insurance_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 保险类型正确
    add_assertion "保险类型正确（境内旅游）", weight: 15 do
      actual_type = @insurance_order.insurance_product.product_type
      expect(actual_type).to eq(@product_type),
        "保险类型错误。期望: #{@product_type}, 实际: #{actual_type}"
    end
    
    # 断言3: 保障天数正确
    add_assertion "保障天数正确（#{@days}天）", weight: 15 do
      actual_days = @insurance_order.days
      expect(actual_days).to eq(@days),
        "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
    end
    
    # 断言4: 选择了最便宜的产品（核心评分项）
    add_assertion "选择了最便宜的产品", weight: 30 do
      # 获取所有境内旅游保险产品并计算7天总价
      all_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      # 计算每个产品的7天总价
      products_with_price = all_products.map do |p|
        {
          product: p,
          total_price: p.price_per_day * @days
        }
      end
      
      # 找到最便宜的
      cheapest = products_with_price.min_by { |p| p[:total_price] }
      
      actual_total = @insurance_order.insurance_product.price_per_day * @days
      cheapest_total = cheapest[:total_price]
      
      expect(@insurance_order.insurance_product_id).to eq(cheapest[:product].id),
        "未选择最便宜的产品。" \
        "应选: #{cheapest[:product].name}（#{cheapest[:product].company}，每天#{cheapest[:product].price_per_day}元，#{@days}天共#{cheapest_total}元），" \
        "实际选择: #{@insurance_order.insurance_product.name}（#{@insurance_order.insurance_product.company}，每天#{@insurance_order.insurance_product.price_per_day}元，#{@days}天共#{actual_total}元）"
    end
    
    # 断言5: 订单总价计算正确
    add_assertion "订单总价计算正确", weight: 20 do
      expected_unit_price = @insurance_order.insurance_product.price_per_day * @insurance_order.days
      expected_total = expected_unit_price * @insurance_order.quantity
      actual_total = @insurance_order.total_price
      
      expect(actual_total).to eq(expected_total),
        "订单总价错误。期望: #{expected_total}元（单价#{expected_unit_price}元 × #{@insurance_order.quantity}人），实际: #{actual_total}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      product_type: @product_type,
      days: @days,
      quantity: @quantity,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @product_type = data['product_type']
    @days = data['days']
    @quantity = data['quantity']
    @start_date = Date.parse(data['start_date'])
    @end_date = Date.parse(data['end_date'])
    
    # 重新加载可用产品列表
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
  end
  
  # 模拟 AI Agent 操作：购买境内旅游保险，选择最便宜的产品
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找境内旅游保险产品
    available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
    
    raise "未找到符合条件的保险产品" if available_products.empty?
    
    # 3. 计算每个产品的7天总价，选择最便宜的
    cheapest_product = available_products.min_by { |p| p.price_per_day * @days }
    
    raise "未找到可用的保险产品" unless cheapest_product
    
    # 4. 创建保险订单
    unit_price = cheapest_product.price_per_day * @days
    
    insurance_order = InsuranceOrder.create!(
      user_id: user.id,
      insurance_product_id: cheapest_product.id,
      source: 'standalone',  # 单独购买
      start_date: @start_date,
      end_date: @end_date,
      days: @days,
      destination: '境内旅游',
      destination_type: 'domestic',
      insured_persons: ['张三'],
      unit_price: unit_price,
      quantity: @quantity,
      total_price: unit_price * @quantity,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_insurance_order',
      order_id: insurance_order.id,
      order_number: insurance_order.order_number,
      insurance_name: cheapest_product.name,
      company: cheapest_product.company,
      price_per_day: cheapest_product.price_per_day,
      days: @days,
      unit_price: unit_price,
      quantity: @quantity,
      total_price: insurance_order.total_price,
      user_email: user.email
    }
  end
end
