# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例66: 购买泰国流量包（泰国、语音包类型）
# 
# 任务描述:
#   搜索流量包 → 选择泰国地区 → 选语音包套餐 → 填写手机号 → 创建订单
#   
#   套餐类型: 语音包（支持境外拨打回境内，区别于天包/月包）
#   泰国语音包选项: 100分钟(68元)、200分钟(118元)、500分钟(268元)
#   选择: 泰国语音包100分钟，68元
#   运营商: 中国电信 180 2712 8600
#   有效期: 30天
#   语音时长: 100分钟语音
#   手机号: 13700137000
#   总价: 68×1=68元
# 
# 操作步骤:
#   1. 浏览流量包: 选择泰国地区
#   2. 查看套餐: 100分钟(68元)、200分钟(118元)、500分钟(268元)
#   3. 选择100分钟: 68元（泰国语音包100分钟）
#   4. 填写手机号: 13700137000
#   5. 计算总价: 68×1=68元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型=data_plan (15分)
#   - 地区正确（泰国） (15分)
#   - 选择了泰国语音包流量包 (30分)
#   - 总价=68元 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v066_buy_thailand_data_plan_1day_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V066BuyThailandDataPlan1dayValidator < BaseValidator
  self.validator_id = 'v066_buy_thailand_data_plan_1day_validator'
  self.task_id = '5911f0c3-51a6-470b-a262-304a3c34c010'
  self.title = '购买泰国流量包（语音包、68元）'
  self.description = '搜索泰国流量包产品，选择语音包套餐（支持境外拨打回境内）并成功创建订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @region = '泰国'
    @data_limit = '100分钟语音'
    @quantity = 1
    
    # 查找符合条件的流量包（注意：查询基线数据 data_version=0）
    matching_data_plans = InternetDataPlan.where(
      region: @region,
      data_limit: @data_limit,
      data_version: 0
    )
    
    @matching_count = matching_data_plans.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请购买一份泰国语音包100分钟流量包",
      region: @region,
      data_limit: @data_limit,
      quantity: @quantity,
      hint: "泰国语音包流量包选项: 100分钟(68元)、200分钟(118元)、500分钟(268元)。选择100分钟套餐，68元。手机号: 13700137000",
      matching_count: @matching_count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @order = InternetOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何境外上网订单记录"
    end
    
    return unless @order # 如果没有订单，后续断言无法继续
    
    # 断言2: 订单类型正确（data_plan）
    add_assertion "订单类型正确（data_plan）", weight: 15 do
      expect(@order.order_type).to eq('data_plan'),
        "订单类型不正确。预期: data_plan, 实际: #{@order.order_type}"
    end
    
    # 断言3: 地区正确
    add_assertion "地区正确（泰国）", weight: 15 do
      expect(@order.region).to eq(@region),
        "地区不正确。预期: #{@region}, 实际: #{@order.region}"
    end
    
    # 断言4: 选择了泰国语音包流量包
    add_assertion "选择了泰国语音包流量包", weight: 30 do
      data_plan = @order.orderable
      expect(data_plan).not_to be_nil, "未选择具体的流量包产品"
      expect(data_plan.region).to eq(@region), "流量包地区不匹配"
      expect(data_plan.data_limit).to eq(@data_limit),
        "流量包语音时长不匹配。预期: #{@data_limit}, 实际: #{data_plan.data_limit}"
      expect(data_plan.plan_type).to eq('语音包'),
        "流量包类型不匹配。预期: 语音包, 实际: #{data_plan.plan_type}"
    end
    
    # 断言5: 总价正确
    add_assertion "总价正确（68元）", weight: 20 do
      data_plan = @order.orderable
      expected_price = data_plan.price * @quantity
      
      expect(@order.total_price).to eq(expected_price),
        "总价不正确。预期: #{expected_price}元（#{data_plan.price}元 × #{@quantity}份），实际: #{@order.total_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      region: @region,
      data_limit: @data_limit,
      quantity: @quantity,
      matching_count: @matching_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @data_limit = data['data_limit']
    @quantity = data['quantity']
    @matching_count = data['matching_count']
  end
  
  # 模拟 AI Agent 操作：购买泰国语音包流量包
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的流量包（语音包类型）
    matching_data_plans = InternetDataPlan.where(
      region: @region,
      data_limit: @data_limit,
      data_version: 0
    )
    
    # 随机选择一个
    target_data_plan = matching_data_plans.sample
    
    # 3. 创建订单
    order = InternetOrder.create!(
      orderable: target_data_plan,
      user_id: user.id,
      order_type: 'data_plan',
      region: @region,
      quantity: @quantity,
      rental_info: {
      validity_days: target_data_plan.validity_days,
        unit_price: target_data_plan.price
      }.to_json,
      total_price: target_data_plan.price * @quantity,
      contact_info: { phone: '13700137000' }.to_json,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: order.id,
      data_plan_name: target_data_plan.name,
      price: target_data_plan.price,
      data_limit: target_data_plan.data_limit,
      total_price: order.total_price,
      user_email: user.email
    }
  end
end