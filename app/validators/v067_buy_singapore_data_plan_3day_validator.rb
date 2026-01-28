# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例67: 购买新加坡流量包（新加坡、3天、天包类型）
# 
# 任务描述:
#   搜索流量包 → 选择新加坡地区 → 选3天天包套餐 → 填写手机号 → 创建订单
#   
#   套餐类型: 天包（按天计费，区别于月包/语音包）
#   新加坡天包选项: 1天(26元)、3天(65元)、7天(125元)
#   选择: 新加坡3天漫游包+10元话费券，65元
#   运营商: 中国电信 180 2712 8600
#   流量: 0.5GB/天，4G/5G漫游
#   手机号: 13600136000
#   总价: 65×1=65元
# 
# 操作步骤:
#   1. 浏览流量包: 选择新加坡地区
#   2. 查看套餐: 1天(26元)、3天(65元)、7天(125元)
#   3. 选择3天: 65元（新加坡3天漫游包+10元话费券）
#   4. 填写手机号: 13600136000
#   5. 计算总价: 65×1=65元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型=data_plan (15分)
#   - 地区正确（新加坡） (15分)
#   - 选择了新加坡3天流量包 (30分)
#   - 总价=65元 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v067_buy_singapore_data_plan_3day_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V067BuySingaporeDataPlan3dayValidator < BaseValidator
  self.validator_id = 'v067_buy_singapore_data_plan_3day_validator'
  self.title = '购买新加坡流量包（3天天包、65元）'
  self.description = '搜索新加坡流量包产品，选择3天天包套餐（按天计费）并成功创建订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @region = '新加坡'
    @validity_days = 3
    @quantity = 1
    
    # 查找符合条件的流量包（注意：查询基线数据 data_version=0）
    matching_data_plans = InternetDataPlan.where(
      region: @region,
      validity_days: @validity_days,
      data_version: 0
    )
    
    @matching_count = matching_data_plans.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请购买一份新加坡3天流量包",
      region: @region,
      validity_days: @validity_days,
      quantity: @quantity,
      hint: "新加坡天包流量包选项: 1天(26元)、3天(65元)、7天(125元)。选择3天天包套餐，65元。手机号: 13600136000",
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
    add_assertion "地区正确（新加坡）", weight: 15 do
      expect(@order.region).to eq(@region),
        "地区不正确。预期: #{@region}, 实际: #{@order.region}"
    end
    
    # 断言4: 选择了新加坡3天天包流量包
    add_assertion "选择了新加坡3天天包流量包", weight: 30 do
      data_plan = @order.orderable
      expect(data_plan).not_to be_nil, "未选择具体的流量包产品"
      expect(data_plan.region).to eq(@region), "流量包地区不匹配"
      expect(data_plan.validity_days).to eq(@validity_days),
        "流量包天数不匹配。预期: #{@validity_days}天, 实际: #{data_plan.validity_days}天"
      expect(data_plan.plan_type).to eq('天包'),
        "流量包类型不匹配。预期: 天包, 实际: #{data_plan.plan_type}"
    end
    
    # 断言5: 总价正确
    add_assertion "总价正确（65元）", weight: 20 do
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
      validity_days: @validity_days,
      quantity: @quantity,
      matching_count: @matching_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @validity_days = data['validity_days']
    @quantity = data['quantity']
    @matching_count = data['matching_count']
  end
  
  # 模拟 AI Agent 操作：购买新加坡3天流量包
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的流量包
    matching_data_plans = InternetDataPlan.where(
      region: @region,
      validity_days: @validity_days,
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
      contact_info: { phone: '13600136000' }.to_json,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: order.id,
      data_plan_name: target_data_plan.name,
      price: target_data_plan.price,
      validity_days: @validity_days,
      total_price: order.total_price,
      user_email: user.email
    }
  end
end
