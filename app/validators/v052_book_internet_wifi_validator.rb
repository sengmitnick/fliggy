# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例52: 预订境外随身WiFi（选择性价比最优）
# 
# 任务描述:
#   Agent 需要在系统中搜索境外WiFi租赁服务，
#   选择最便宜的WiFi套餐并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索可用的境外WiFi产品（从多个地区中选择）
#   2. 需要对比不同WiFi的日租金价格
#   3. 需要考虑租赁天数计算总价
#   4. 需要选择最低日租金的WiFi
#   5. 需要填写订单信息（联系人、地址等）
#   ❌ 不能一次性提供：需要先搜索→对比价格→选择最优→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（wifi）(15分)
#   - 选择了具体的WiFi产品 (15分)
#   - 选择了最便宜的WiFi (30分)
#   - 订单价格正确 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v052_book_internet_wifi_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V052BookInternetWifiValidator < BaseValidator
  self.validator_id = 'v052_book_internet_wifi_validator'
  self.title = '预订境外随身WiFi（选择性价比最优）'
  self.description = '需要搜索境外WiFi租赁服务，选择日租金最低的产品并成功创建订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @rental_days = 5  # 租赁5天
    @quantity = 1     # 1台设备
    
    # 查找所有可用的WiFi产品（注意：查询基线数据 data_version=0）
    @available_wifis = InternetWifi.where(data_version: 0)
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订境外随身WiFi（租赁#{@rental_days}天，#{@quantity}台），选择日租金最便宜的产品",
      rental_days: @rental_days,
      quantity: @quantity,
      hint: "系统中有多个地区的WiFi产品，请对比日租金（daily_price）后选择最便宜的",
      available_wifis_count: @available_wifis.count
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
    add_assertion "订单类型正确（wifi）", weight: 15 do
      actual_type = @internet_order.order_type
      expect(actual_type).to eq('wifi'),
        "订单类型错误。期望: wifi, 实际: #{actual_type}"
    end
    
    # 断言3: 选择了具体的WiFi产品
    add_assertion "选择了具体的WiFi产品", weight: 15 do
      expect(@internet_order.orderable_type).to eq('InternetWifi'), "未选择WiFi产品（orderable_type错误）"
      expect(@internet_order.orderable_id).not_to be_nil, "未选择具体的WiFi产品（orderable_id为空）"
      expect(@internet_order.orderable).not_to be_nil, "WiFi产品记录不存在"
    end
    
    # 断言4: 选择了最便宜的WiFi（核心评分项）
    add_assertion "选择了最便宜的WiFi", weight: 30 do
      # 获取所有可用WiFi
      all_wifis = InternetWifi.where(data_version: 0)
      
      # 找到日租金最低的
      cheapest_wifi = all_wifis.min_by(&:daily_price)
      actual_price = @internet_order.orderable.daily_price
      cheapest_price = cheapest_wifi.daily_price
      
      expect(@internet_order.orderable_id).to eq(cheapest_wifi.id),
        "未选择最便宜的WiFi。" \
        "应选: #{cheapest_wifi.name}（#{cheapest_price}元/天），" \
        "实际选择: #{@internet_order.orderable.name}（#{actual_price}元/天）"
    end
    
    # 断言5: 订单价格正确
    add_assertion "订单价格正确", weight: 20 do
      wifi = @internet_order.orderable
      expected_price = wifi.daily_price * @rental_days * @quantity
      actual_price = @internet_order.total_price
      
      expect(actual_price).to eq(expected_price),
        "订单价格错误。期望: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台），实际: #{actual_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      rental_days: @rental_days,
      quantity: @quantity
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @rental_days = data['rental_days']
    @quantity = data['quantity']
    
    # 重新加载可用WiFi列表
    @available_wifis = InternetWifi.where(data_version: 0)
  end
  
  # 模拟 AI Agent 操作：预订境外随身WiFi，选择最便宜的
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找所有可用的WiFi产品
    available_wifis = InternetWifi.where(data_version: 0)
    
    raise "未找到任何可用的WiFi产品" if available_wifis.empty?
    
    # 3. 选择日租金最低的WiFi
    cheapest_wifi = available_wifis.min_by(&:daily_price)
    
    raise "未找到可用的WiFi产品" unless cheapest_wifi
    
    # 4. 计算总价：日租金 × 天数 × 数量
    total_price = cheapest_wifi.daily_price * @rental_days * @quantity
    
    # 5. 创建境外上网订单
    internet_order = InternetOrder.create!(
      user_id: user.id,
      orderable_type: 'InternetWifi',
      orderable_id: cheapest_wifi.id,
      order_type: 'wifi',
      region: cheapest_wifi.region,
      quantity: @quantity,
      total_price: total_price,
      delivery_method: 'mail',
      delivery_info: JSON.generate({
        address: '北京市朝阳区建国路118号',
        method: 'mail'
      }),
      contact_info: JSON.generate({
        name: '张三',
        phone: '13800138000'
      }),
      rental_info: JSON.generate({
        start_date: (Date.current + 7.days).to_s,
        end_date: (Date.current + 7.days + @rental_days.days).to_s,
        rental_days: @rental_days,
        unit_price: cheapest_wifi.daily_price.to_f
      }),
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: internet_order.id,
      order_number: internet_order.order_number,
      wifi_name: cheapest_wifi.name,
      region: cheapest_wifi.region,
      daily_price: cheapest_wifi.daily_price,
      rental_days: @rental_days,
      quantity: @quantity,
      total_price: internet_order.total_price,
      user_email: user.email
    }
  end
end
