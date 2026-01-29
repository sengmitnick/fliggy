# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例50: 购买成都出行的境内旅游保险（后天出发，7天，1人，该城市最便宜产品）
# 
# 任务描述:
#   Agent 需要为成都出行购买境内旅游保险（后天出发），
#   根据成都的差异化定价选择7天保障期最便宜的产品并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品（domestic类型）
#   2. 需要指定出行时间（后天开始）
#   3. 需要根据目的地城市（成都）获取差异化定价
#   4. 需要计算7天的总价（city_price_per_day × 7）
#   5. 需要对比多个保险公司在成都的价格
#   6. 需要选择在成都最便宜的产品
#   7. 需要填写保险信息（保障时间、目的地城市、被保险人等）
#   ❌ 不能一次性提供：需要先搜索→查询城市价格→计算价格→对比→购买
# 
# 评分标准:
#   - 订单已创建 (10分)
#   - 保险类型正确（境内旅游）(10分)
#   - 目的地城市正确（成都）(10分)
#   - 出行开始时间正确（后天）(15分)
#   - 保障天数正确（7天）(10分)
#   - 根据成都差异化定价选择了最便宜的产品 (30分)
#   - 订单总价计算正确（使用成都的城市价格）(15分)
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
  self.task_id = '1eb4c6df-76fd-415c-bf02-08b4ce823dc5'
  self.title = '购买成都出行的境内旅游保险（后天出发，7天，1人，该城市最便宜）'
  self.description = '为成都出行购买境内旅游保险（后天出发），根据成都的差异化定价选择7天保障期最便宜的产品'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @product_type = 'domestic'
    @destination_city = '成都'
    @days = 7
    @quantity = 1
    @start_date = Date.current + 2.days  # 后天开始（2天后）
    @end_date = @start_date + @days - 1  # 保障结束日期
    
    # 查找目的地城市
    @city = City.find_by!(name: @destination_city, data_version: 0)
    
    # 查找在成都可用的境内旅游保险产品（注意：查询基线数据 data_version=0）
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .available_in_city(@city.id)
    
    # 计算相对时间描述
    days_until_start = (@start_date - Date.current).to_i
    start_time_desc = case days_until_start
    when 0 then "今天"
    when 1 then "明天"
    when 2 then "后天"
    else "#{days_until_start}天后"
    end
    
    # 返回给 Agent 的任务信息
    {
      task: "请为#{@destination_city}出行购买境内旅游保险（#{start_time_desc}出发，保障期#{@days}天，#{@quantity}人），选择在#{@destination_city}最便宜的产品",
      product_type: "境内旅游",
      destination: @destination_city,
      start_time: start_time_desc,
      days: @days,
      quantity: @quantity,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      hint: "系统中有多家保险公司提供该产品，不同城市价格不同。请根据#{@destination_city}的每日单价计算#{@days}天总价后选择最便宜的",
      available_products_count: @available_products.count,
      note: "保险价格因目的地城市而异，请确保使用#{@destination_city}的差异化定价。保障从#{start_time_desc}（#{@start_date}）开始"
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 10 do
      @insurance_order = InsuranceOrder.order(created_at: :desc).first
      expect(@insurance_order).not_to be_nil, "未找到任何保险订单记录"
    end
    
    return unless @insurance_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 保险类型正确
    add_assertion "保险类型正确（境内旅游）", weight: 10 do
      actual_type = @insurance_order.insurance_product.product_type
      expect(actual_type).to eq(@product_type),
        "保险类型错误。期望: #{@product_type}, 实际: #{actual_type}"
    end
    
    # 断言3: 目的地城市正确
    add_assertion "目的地城市正确（#{@destination_city}）", weight: 10 do
      actual_destination = @insurance_order.destination
      expect(actual_destination).to eq(@destination_city),
        "目的地城市错误。期望: #{@destination_city}, 实际: #{actual_destination || '未填写'}"
    end
    
    # 断言4: 出行开始时间正确（后天）
    add_assertion "出行开始时间正确（后天，#{@start_date}）", weight: 15 do
      actual_start_date = @insurance_order.start_date
      expect(actual_start_date).to eq(@start_date),
        "出行开始时间错误。期望: #{@start_date}（后天）, 实际: #{actual_start_date}"
    end
    
    # 断言5: 保障天数正确
    add_assertion "保障天数正确（#{@days}天）", weight: 10 do
      actual_days = @insurance_order.days
      expect(actual_days).to eq(@days),
        "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
    end
    
    # 断言6: 根据成都差异化定价选择了最便宜的产品（核心评分项）
    add_assertion "根据#{@destination_city}差异化定价选择了最便宜的产品", weight: 30 do
      # 获取所有在成都可用的境内旅游保险产品
      all_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
       .available_in_city(@city.id)
      
      # 计算每个产品在成都的7天总价
      products_with_price = all_products.map do |p|
        city_price = p.price_for_city(@city.id)
        {
          product: p,
          city_price_per_day: city_price,
          total_price: city_price * @days
        }
      end
      
      # 找到在成都最便宜的
      cheapest = products_with_price.min_by { |p| p[:total_price] }
      
      actual_city_price = @insurance_order.insurance_product.price_for_city(@city.id)
      actual_total = actual_city_price * @days
      cheapest_total = cheapest[:total_price]
      
      expect(@insurance_order.insurance_product_id).to eq(cheapest[:product].id),
        "未选择在#{@destination_city}最便宜的产品。" \
        "应选: #{cheapest[:product].name}（#{cheapest[:product].company}，在#{@destination_city}每天#{cheapest[:city_price_per_day]}元，#{@days}天共#{cheapest_total}元），" \
        "实际选择: #{@insurance_order.insurance_product.name}（#{@insurance_order.insurance_product.company}，在#{@destination_city}每天#{actual_city_price}元，#{@days}天共#{actual_total}元）"
    end
    
    # 断言7: 订单总价计算正确（使用成都的城市价格）
    add_assertion "订单总价计算正确（使用#{@destination_city}的城市价格）", weight: 15 do
      city_price_per_day = @insurance_order.insurance_product.price_for_city(@city.id)
      expected_unit_price = city_price_per_day * @insurance_order.days
      expected_total = expected_unit_price * @insurance_order.quantity
      actual_total = @insurance_order.total_price
      
      expect(actual_total).to eq(expected_total),
        "订单总价错误。期望: #{expected_total}元（在#{@destination_city}单价#{expected_unit_price}元 × #{@insurance_order.quantity}人），实际: #{actual_total}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      product_type: @product_type,
      destination_city: @destination_city,
      city_id: @city&.id,
      days: @days,
      quantity: @quantity,
      start_date: @start_date&.to_s,
      end_date: @end_date&.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @product_type = data['product_type']
    @destination_city = data['destination_city']
    @days = data['days']
    @quantity = data['quantity']
    @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
    @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
    
    # 重新加载城市和可用产品列表
    if data['city_id']
      @city = City.find(data['city_id'])
      @available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
       .available_in_city(@city.id)
    end
  end
  
  # 模拟 AI Agent 操作：为成都出行购买境内旅游保险，根据成都差异化定价选择最便宜的产品
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找在成都可用的境内旅游保险产品
    available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .available_in_city(@city.id)
    
    raise "未找到在#{@destination_city}可用的保险产品" if available_products.empty?
    
    # 3. 根据成都的差异化定价计算每个产品的7天总价，选择最便宜的
    cheapest_product = available_products.min_by do |p|
      p.price_for_city(@city.id) * @days
    end
    
    raise "未找到在#{@destination_city}可用的保险产品" unless cheapest_product
    
    # 4. 使用成都的城市价格创建保险订单
    city_price_per_day = cheapest_product.price_for_city(@city.id)
    unit_price = city_price_per_day * @days
    
    insurance_order = InsuranceOrder.create!(
      user_id: user.id,
      insurance_product_id: cheapest_product.id,
      source: 'standalone',  # 单独购买
      start_date: @start_date,
      end_date: @end_date,
      days: @days,
      destination: @destination_city,
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
      destination: @destination_city,
      base_price_per_day: cheapest_product.price_per_day,
      city_price_per_day: city_price_per_day,
      days: @days,
      unit_price: unit_price,
      quantity: @quantity,
      total_price: insurance_order.total_price,
      user_email: user.email,
      note: "使用#{@destination_city}的差异化定价：#{city_price_per_day}元/天（基础价格：#{cheapest_product.price_per_day}元/天）"
    }
  end
end