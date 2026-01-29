# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例82: 购买滑雪运动保险（长白山，3天，运动医疗保额最高）
# 
# 任务描述:
#   Agent 需要为长白山滑雪之旅购买运动保险，
#   选择运动医疗保额最高的专业滑雪保险产品
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品
#   2. 需要识别适合滑雪场景的产品（scenes包含'滑雪'）
#   3. 需要理解滑雪运动需要专业的运动医疗保障
#   4. 需要对比运动医疗保额（coverage_details.sports_injury）
#   5. 需要选择运动医疗保额最高的产品
#   ❌ 不能一次性提供：需要先搜索→筛选滑雪→对比运动保额→选择
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境内旅游）(15分)
#   - 目的地正确（长白山）(10分)
#   - 产品适合滑雪场景 (20分)
#   - 选择了运动医疗保额最高的产品 (25分)
#   - 保障天数正确（3天）(10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v082_buy_skiing_sports_insurance_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V082BuySkiingSportsInsuranceValidator < BaseValidator
  self.validator_id = 'v082_buy_skiing_sports_insurance_validator'
  self.task_id = '1d4d5de8-989c-46da-b68a-c36ce36fc968'
  self.title = '购买滑雪运动保险（长白山，3天，运动医疗保额最高）'
  self.description = '为长白山滑雪之旅购买运动保险，选择运动医疗保额最高的专业滑雪保险'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @product_type = 'domestic'
    @destination = '长白山'
    @days = 3
    @quantity = 1
    @scene = '滑雪'
    @start_date = Date.current + 10.days  # 10天后开始
    @end_date = @start_date + @days - 1  # 保障结束日期
    
    # 查找适合滑雪的境内旅游保险产品（注意：查询基线数据 data_version=0）
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .select { |p| p.scenes&.include?(@scene) }
    
    # 找到运动医疗保额最高的产品
    @highest_sports_product = @available_products.max_by do |p|
      p.coverage_details['sports_injury'] || p.coverage_details['medical'] || 0
    end
    
    # 返回给 Agent 的任务信息
    {
      task: "请为长白山滑雪之旅购买运动保险（10天后出发，保障期#{@days}天），滑雪属于高风险运动，请选择适合滑雪且运动医疗保额最高的产品",
      product_type: "境内旅游",
      destination: @destination,
      days: @days,
      quantity: @quantity,
      scene: @scene,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      hint: "滑雪属于高风险运动，需要购买专业的滑雪运动保险（scenes包含'滑雪'）。请对比运动医疗保额（coverage_details.sports_injury或medical）后选择最高的",
      available_products_count: @available_products.count,
      note: "滑雪保险通常包含运动意外、运动医疗、滑雪装备损失等保障"
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
    
    # 断言4: 产品适合滑雪场景
    add_assertion "产品适合滑雪场景", weight: 20 do
      scenes = @insurance_order.insurance_product.scenes || []
      has_scene = scenes.include?(@scene)
      
      expect(has_scene).to be_truthy,
        "所选产品不适合滑雪场景。期望: scenes包含'#{@scene}', 实际: scenes=#{scenes.inspect}。" \
        "滑雪属于高风险运动，需要专业的滑雪运动保险"
    end
    
    # 断言5: 选择了运动医疗保额最高的产品（核心评分项）
    add_assertion "选择了运动医疗保额最高的产品", weight: 25 do
      # 获取所有适合滑雪的产品
      all_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
       .select { |p| p.scenes&.include?(@scene) }
      
      # 找到运动医疗保额最高的
      highest_product = all_products.max_by do |p|
        p.coverage_details['sports_injury'] || p.coverage_details['medical'] || 0
      end
      
      actual_coverage = @insurance_order.insurance_product.coverage_details['sports_injury'] || 
                        @insurance_order.insurance_product.coverage_details['medical'] || 0
      highest_coverage = highest_product.coverage_details['sports_injury'] || 
                         highest_product.coverage_details['medical'] || 0
      
      expect(@insurance_order.insurance_product_id).to eq(highest_product.id),
        "未选择运动医疗保额最高的产品。" \
        "应选: #{highest_product.name}（#{highest_product.company}，运动医疗保额#{highest_coverage}元），" \
        "实际选择: #{@insurance_order.insurance_product.name}（#{@insurance_order.insurance_product.company}，运动医疗保额#{actual_coverage}元）。" \
        "滑雪运动应选择运动医疗保额最高的产品"
    end
    
    # 断言6: 保障天数正确
    add_assertion "保障天数正确（#{@days}天）", weight: 10 do
      actual_days = @insurance_order.days
      expect(actual_days).to eq(@days),
        "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
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
    
    @highest_sports_product = @available_products.max_by do |p|
      p.coverage_details['sports_injury'] || p.coverage_details['medical'] || 0
    end
  end
  
  # 模拟 AI Agent 操作：为滑雪之旅购买运动医疗保额最高的保险
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找适合滑雪的境内旅游保险产品
    available_products = InsuranceProduct.where(
      product_type: @product_type,
      data_version: 0
    ).where('min_days <= ? AND max_days >= ?', @days, @days)
     .select { |p| p.scenes&.include?(@scene) }
    
    raise "未找到适合滑雪的保险产品" if available_products.empty?
    
    # 3. 选择运动医疗保额最高的
    highest_sports_product = available_products.max_by do |p|
      p.coverage_details['sports_injury'] || p.coverage_details['medical'] || 0
    end
    
    raise "未找到可用的保险产品" unless highest_sports_product
    
    # 4. 创建保险订单
    unit_price = highest_sports_product.price_per_day * @days
    
    insurance_order = InsuranceOrder.create!(
      user_id: user.id,
      insurance_product_id: highest_sports_product.id,
      source: 'standalone',  # 单独购买
      start_date: @start_date,
      end_date: @end_date,
      days: @days,
      destination: @destination,
      destination_type: 'domestic',
      insured_persons: ['王勇'],
      unit_price: unit_price,
      quantity: @quantity,
      total_price: unit_price * @quantity,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_insurance_order',
      order_id: insurance_order.id,
      insurance_product_name: highest_sports_product.name,
      company: highest_sports_product.company,
      product_type: highest_sports_product.product_type,
      scenes: highest_sports_product.scenes,
      sports_injury_coverage: highest_sports_product.coverage_details['sports_injury'] || highest_sports_product.coverage_details['medical'],
      price_per_day: highest_sports_product.price_per_day,
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