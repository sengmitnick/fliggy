# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例83: 购买全年境外旅行计划（商务人士，全年无限次出行）
# 
# 任务描述:
#   Agent 需要为经常出境的商务人士购买全年旅行计划，
#   选择支持全年无限次出行的境外保险产品
# 
# 复杂度分析:
#   1. 需要搜索"境外旅游"类型的保险产品
#   2. 需要识别全年计划产品（min_days=365且max_days=365）
#   3. 需要理解全年计划支持多次出行
#   4. 需要对比全年计划产品
#   5. 需要理解全年计划通常每日单价更低但总价更高
#   ❌ 不能一次性提供：需要先搜索→识别全年计划→理解优势→购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境外旅游international）(20分)
#   - 产品是全年计划（365天）(30分)
#   - 适合商务出行场景 (15分)
#   - 保障天数正确（365天）(15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v083_buy_annual_travel_plan_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V083BuyAnnualTravelPlanValidator < BaseValidator
  self.validator_id = 'v083_buy_annual_travel_plan_validator'
  self.title = '购买全年境外旅行计划（商务人士，全年无限次出行）'
  self.description = '为经常出境的商务人士购买全年旅行计划，支持全年无限次出行'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @product_type = 'international'
    @days = 365
    @quantity = 1
    @scene = '商务出行'
    @start_date = Date.current + 3.days  # 3天后开始
    @end_date = @start_date + @days - 1  # 保障结束日期
    
    # 查找全年境外旅行计划产品（注意：查询基线数据 data_version=0）
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      min_days: 365,
      max_days: 365,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请为经常出境的商务人士购买全年境外旅行计划（3天后生效，保障期365天），支持全年无限次出行",
      product_type: "境外旅游",
      plan_type: "全年计划",
      days: @days,
      quantity: @quantity,
      scene: @scene,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      hint: "全年旅行计划适合需要多次出境的商务人士，保障期365天，支持全年无限次出行。请选择min_days=365且max_days=365且适合商务出行的产品",
      available_products_count: @available_products.count,
      note: "全年计划虽然总价较高，但平均每天单价很低，适合频繁出境的人士"
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
    
    # 断言2: 保险类型正确（境外旅游）
    add_assertion "保险类型正确（境外旅游international）", weight: 20 do
      actual_type = @insurance_order.insurance_product.product_type
      expect(actual_type).to eq(@product_type),
        "保险类型错误。期望: #{@product_type}（境外旅游），实际: #{actual_type}。" \
        "全年旅行计划属于境外旅游保险类型"
    end
    
    # 断言3: 产品是全年计划（365天）（核心评分项）
    add_assertion "产品是全年计划（365天）", weight: 30 do
      product = @insurance_order.insurance_product
      min_days = product.min_days
      max_days = product.max_days
      
      is_annual = (min_days == 365 && max_days == 365)
      
      expect(is_annual).to be_truthy,
        "所选产品不是全年计划。期望: min_days=365且max_days=365, 实际: min_days=#{min_days}, max_days=#{max_days}。" \
        "全年旅行计划支持365天保障期，可以全年无限次出行"
    end
    
    # 断言4: 适合商务出行场景
    add_assertion "适合商务出行场景", weight: 15 do
      scenes = @insurance_order.insurance_product.scenes || []
      has_scene = scenes.include?(@scene)
      
      expect(has_scene).to be_truthy,
        "所选产品不适合商务出行场景。期望: scenes包含'#{@scene}', 实际: scenes=#{scenes.inspect}。" \
        "全年旅行计划通常适合经常出境的商务人士"
    end
    
    # 断言5: 保障天数正确（365天）
    add_assertion "保障天数正确（365天）", weight: 15 do
      actual_days = @insurance_order.days
      expect(actual_days).to eq(@days),
        "保障天数错误。期望: #{@days}天（全年），实际: #{actual_days}天"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      product_type: @product_type,
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
    @days = data['days']
    @quantity = data['quantity']
    @scene = data['scene']
    @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
    @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
    
    # 重新加载可用产品列表
    @available_products = InsuranceProduct.where(
      product_type: @product_type,
      min_days: 365,
      max_days: 365,
      data_version: 0
    )
  end
  
  # 模拟 AI Agent 操作：为商务人士购买全年境外旅行计划
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找全年境外旅行计划产品
    available_products = InsuranceProduct.where(
      product_type: @product_type,
      min_days: 365,
      max_days: 365,
      data_version: 0
    )
    
    raise "未找到全年旅行计划产品" if available_products.empty?
    
    # 3. 选择适合商务出行的全年计划
    selected_product = available_products.find { |p| p.scenes&.include?(@scene) }
    selected_product ||= available_products.first  # 如果没有商务标签，选择第一个
    
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
      destination: '全球多国',
      destination_type: 'international',
      insured_persons: ['李经理'],
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
      plan_type: '全年计划',
      scenes: selected_product.scenes,
      price_per_day: selected_product.price_per_day,
      days: @days,
      quantity: @quantity,
      unit_price: unit_price,
      total_price: insurance_order.total_price,
      start_date: @start_date.to_s,
      end_date: @end_date.to_s,
      user_email: user.email
    }
  end
end
