# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例53: 购买流量包（中国香港、1天、选最便宜35元）
# 
# 任务描述:
#   搜索流量包 → 对比价格 → 选最便宜的 → 填写手机号 → 创建订单
#   
#   可选流量包: 中国香港1天(35元)、3天(88元)、5天(108元/128元)、7天(168元)
#   最便宜: 香港1天漫游包+10元话费券，35元
#   运营商: 中国电信 180 2712 8600
#   流量: 0.4GB/天，4G/5G漫游
#   手机号: 13800138000
# 
# 操作步骤:
#   1. 浏览流量包: 中国香港1天、3天、5天、7天
#   2. 对比价格: 35元(1天)、88元(3天)、108元(5天)、128元(5天)、168元(7天)
#   3. 选最便宜: 35元（香港1天漫游包+10元话费券）
#   4. 填写手机号: 13800138000
#   5. 计算总价: 35×1=35元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型=data_plan (15分)
#   - 选了具体流量包产品 (15分)
#   - 选了最便宜35元的香港1天漫游包 (30分)
#   - 总价=35元 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v053_buy_data_plan_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V053BuyDataPlanValidator < BaseValidator
  self.validator_id = 'v053_buy_data_plan_validator'
  self.title = '购买流量包（中国香港、1天、选最便宜35元）'
  self.description = '需要搜索流量包产品，选择价格最低的套餐并成功创建订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @quantity = 1     # 1份
    
    # 查找所有可用的流量包产品（注意：查询基线数据 data_version=0）
    @available_data_plans = InternetDataPlan.where(data_version: 0)
    
    # 返回给 Agent 的任务信息
    {
      task: "购买流量包: 1份、选最便宜的、填手机号",
      quantity: @quantity,
      hint: "流量包选项: 中国香港1天(35元)、3天(88元)、5天(108元/128元)、7天(168元)。对比后选最便宜35元的。手机号: 13800138000",
      available_data_plans_count: @available_data_plans.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @internet_order = InternetOrder.order(created_at: :desc).first
      expect(@internet_order).not_to be_nil, "未找到任何境外上网订单记录"
    end
    
    return unless @internet_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 订单类型正确
    add_assertion "订单类型正确（data_plan）", weight: 15 do
      actual_type = @internet_order.order_type
      expect(actual_type).to eq('data_plan'),
        "订单类型错误。期望: data_plan, 实际: #{actual_type}"
    end
    
    # 断言3: 选择了具体的流量包产品
    add_assertion "选择了具体的流量包产品", weight: 15 do
      expect(@internet_order.orderable_type).to eq('InternetDataPlan'), "未选择流量包产品（orderable_type错误）"
      expect(@internet_order.orderable_id).not_to be_nil, "未选择具体的流量包产品（orderable_id为空）"
      expect(@internet_order.orderable).not_to be_nil, "流量包产品记录不存在"
    end
    
    # 断言4: 选择了最便宜的流量包（核心评分项）
    add_assertion "选择了最便宜的流量包", weight: 30 do
      # 获取所有可用流量包
      all_data_plans = InternetDataPlan.where(data_version: 0)
      
      # 找到价格最低的
      cheapest_data_plan = all_data_plans.min_by(&:price)
      actual_price = @internet_order.orderable.price
      cheapest_price = cheapest_data_plan.price
      
      expect(@internet_order.orderable_id).to eq(cheapest_data_plan.id),
        "未选择最便宜的流量包。" \
        "应选: #{cheapest_data_plan.name}（#{cheapest_price}元），" \
        "实际选择: #{@internet_order.orderable.name}（#{actual_price}元）"
    end
    
    # 断言5: 订单价格正确
    add_assertion "订单价格正确", weight: 20 do
      data_plan = @internet_order.orderable
      expected_price = data_plan.price * @quantity
      actual_price = @internet_order.total_price
      
      expect(actual_price).to eq(expected_price),
        "订单价格错误。期望: #{expected_price}元（#{data_plan.price}元 × #{@quantity}份），实际: #{actual_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      quantity: @quantity
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @quantity = data['quantity']
    
    # 重新加载可用流量包列表
    @available_data_plans = InternetDataPlan.where(data_version: 0)
  end
  
  # 模拟 AI Agent 操作：购买流量包，选择最便宜的
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找所有可用的流量包产品
    available_data_plans = InternetDataPlan.where(data_version: 0)
    
    raise "未找到任何可用的流量包产品" if available_data_plans.empty?
    
    # 3. 选择价格最低的流量包
    cheapest_data_plan = available_data_plans.min_by(&:price)
    
    raise "未找到可用的流量包产品" unless cheapest_data_plan
    
    # 4. 计算总价：单价 × 数量
    total_price = cheapest_data_plan.price * @quantity
    
    # 5. 创建境外上网订单
    internet_order = InternetOrder.create!(
      user_id: user.id,
      orderable_type: 'InternetDataPlan',
      orderable_id: cheapest_data_plan.id,
      order_type: 'data_plan',
      region: cheapest_data_plan.region,
      quantity: @quantity,
      total_price: total_price,
      delivery_method: nil,
      contact_info: JSON.generate({
        phone: '13800138000'
      }),
      rental_info: JSON.generate({
        validity_days: cheapest_data_plan.validity_days,
        unit_price: cheapest_data_plan.price.to_f
      }),
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: internet_order.id,
      order_number: internet_order.order_number,
      data_plan_name: cheapest_data_plan.name,
      region: cheapest_data_plan.region,
      price: cheapest_data_plan.price,
      validity_days: cheapest_data_plan.validity_days,
      quantity: @quantity,
      total_price: internet_order.total_price,
      user_email: user.email
    }
  end
end
