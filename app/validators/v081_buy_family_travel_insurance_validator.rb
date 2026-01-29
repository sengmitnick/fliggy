# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例81: 购买家庭旅游保险（三亚出行，3人，7天，支持儿童保障）
# 
# 任务描述:
#   Agent 需要为家庭（2成人+1儿童）购买三亚出行的旅游保险，
#   选择适合亲子游且支持儿童保障的产品
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品
#   2. 需要识别适合亲子游场景的产品（scenes包含'亲子游'）
#   3. 需要理解家庭保险需要儿童保障
#   4. 需要对比适合亲子游的产品
#   5. 需要填写3人的保险信息
#   ❌ 不能一次性提供：需要先搜索→筛选亲子游→确认儿童保障→购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境内旅游）(15分)
#   - 目的地正确（三亚）(10分)
#   - 保障天数正确（7天）(10分)
#   - 人数正确（3人）(10分)
#   - 产品适合亲子游场景 (25分)
#   - 订单价格计算正确 (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v081_buy_family_travel_insurance_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V081BuyFamilyTravelInsuranceValidator < BaseValidator
  self.validator_id = 'v081_buy_family_travel_insurance_validator'
  self.title = '购买家庭旅游保险（三亚出行，3人，7天，适合亲子游）'
  self.description = '为家庭（2成人+1儿童）购买三亚出行的旅游保险，选择适合亲子游场景的产品'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @product_type = 'domestic'
    @destination = '三亚'
    @days = 7
    @quantity = 3  # 2成人+1儿童
    @scene = '亲子游'
    @start_date = Date.current + 7.days  # 7天后开始
    @end_date = @start_date + @days - 1  # 保障结束日期
    
    # 查找适合亲子游的境内旅游保险产品（注意：查询基线数据 data_version=0）
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .select { |p| p.scenes&.include?(@scene) }
    
    # 返回给 Agent 的任务信息
    {
      task: "请为家庭（2成人+1儿童）购买#{@destination}出行的旅游保险（7天后出发，保障期#{@days}天，共#{@quantity}人），选择适合亲子游且支持儿童保障的产品",
      product_type: "境内旅游",
      destination: @destination,
      days: @days,
      quantity: @quantity,
      scene: @scene,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      hint: "三亚是热门的亲子游目的地，请选择适合亲子游场景（scenes包含'亲子游'）的保险产品，这类产品通常包含儿童特别保障",
      available_products_count: @available_products.count,
      note: "家庭保险通常支持一家人共同投保，儿童保障包括意外伤害、突发疾病等"
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
        "保险类型错误。期望: #{@product_type}（境内旅游），实际: #{actual_type}"
    end
    
    # 断言3: 目的地正确
    add_assertion "目的地正确（#{@destination}）", weight: 10 do
      actual_destination = @insurance_order.destination
      expect(actual_destination).to include(@destination),
        "目的地错误。期望包含: #{@destination}, 实际: #{actual_destination || '未填写'}"
    end
    
    # 断言4: 保障天数正确
    add_assertion "保障天数正确（#{@days}天）", weight: 10 do
      actual_days = @insurance_order.days
      expect(actual_days).to eq(@days),
        "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
    end
    
    # 断言5: 人数正确（3人）
    add_assertion "人数正确（#{@quantity}人）", weight: 10 do
      actual_quantity = @insurance_order.quantity
      expect(actual_quantity).to eq(@quantity),
        "购买人数错误。期望: #{@quantity}人（家庭），实际: #{actual_quantity}人"
    end
    
    # 断言6: 产品适合亲子游场景（核心评分项）
    add_assertion "产品适合亲子游场景", weight: 25 do
      scenes = @insurance_order.insurance_product.scenes || []
      has_scene = scenes.include?(@scene)
      
      expect(has_scene).to be_truthy,
        "所选产品不适合亲子游场景。期望: scenes包含'#{@scene}', 实际: scenes=#{scenes.inspect}。" \
        "亲子游保险通常包含儿童特别保障，更适合带孩子出行的家庭"
    end
    
    # 断言7: 订单价格计算正确
    add_assertion "订单价格计算正确", weight: 10 do
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
      destination: @destination,
      days: @days,
      quantity: @quantity,
      scene: @scene,
      start_date: @start_date&.to_s,
      end_date: @end_date&.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @product_type = data['product_type']
    @destination = data['destination']
    @days = data['days']
    @quantity = data['quantity']
    @scene = data['scene']
    @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
    @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
    
    # 重新加载可用产品列表
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .select { |p| p.scenes&.include?(@scene) }
  end
  
  # 模拟 AI Agent 操作：为家庭购买适合亲子游的旅游保险
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找适合亲子游的境内旅游保险产品
    available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .select { |p| p.scenes&.include?(@scene) }
    
    raise "未找到适合亲子游的保险产品" if available_products.empty?
    
    # 3. 选择第一个适合亲子游的产品
    selected_product = available_products.first
    
    raise "未找到可用的保险产品" unless selected_product
    
    # 4. 创建保险订单
    unit_price = selected_product.price_per_day * @days
    
    insurance_order = InsuranceOrder.create!(
      user_id: user.id,
      insurance_product_id: selected_product.id,
      source: 'standalone',  # 单独购买
      start_date: @start_date,
      end_date: @end_date,
      days: @days,
      destination: @destination,
      destination_type: 'domestic',
      insured_persons: ['张三（爸爸）', '李四（妈妈）', '张小明（儿童，8岁）'],
      unit_price: unit_price,
      quantity: @quantity,
      total_price: unit_price * @quantity,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_insurance_order',
      order_id: insurance_order.id,
      insurance_product_name: selected_product.name,
      company: selected_product.company,
      product_type: selected_product.product_type,
      scenes: selected_product.scenes,
      price_per_day: selected_product.price_per_day,
      days: @days,
      quantity: @quantity,
      unit_price: unit_price,
      total_price: insurance_order.total_price,
      destination: @destination,
      start_date: @start_date.to_s,
      user_email: user.email
    }
  end
end
