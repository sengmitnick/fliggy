# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例52: 预订境外随身WiFi（中国香港、租用1台、7天后取件、共租5天、选最便宜）
# 
# 任务描述:
#   搜索WiFi → 对比价格 → 选最便宜的 → 填写信息 → 创建订单
#   
#   可选地区: 中国香港(13-37元/天)、欧洲5国通用(20元/天)、欧洲6国通用5G(35元/天)、欧洲8国通用(25元/天)、欧洲10国通用(30元/天)
#   最便宜: 中国香港 4G网·500MB/天，13元/天
#   租赁参数: 1台，5天，7天后取件
#   取件地址: 北京市朝阳区建国路118号
#   联系人: 张三 13800138000
#   总价: 13×5×1+500=565元
# 
# 操作步骤:
#   1. 浏览地区: 中国香港、欧洲5国、欧洲6国、欧洲8国、欧洲10国
#   2. 对比价格: 13元(香港4G)、17元(香港4G无限)、20元(欧洲5国)、25元(欧洲8国)、30元(欧洲10国)、35元(香港5G/欧洲6国5G)
#   3. 选最便宜: 13元/天（中国香港4G·500MB/天）
#   4. 填写租赁: start_date=今天+7天、end_date=今天+12天、rental_days=5、unit_price=13.0
#   5. 填写地址: address="北京市朝阳区建国路118号"、method="mail"
#   6. 填写联系人: name="张三"、phone="13800138000"
#   7. 计算总价: 13×5×1+500=565元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型=wifi (15分)
#   - 选了具体WiFi产品 (15分)
#   - 选了最便宜13元/天的香港4G·500MB (30分)
#   - 总价=565元（含500元押金）、地址=北京市朝阳区建国路118号、租期=5天 (20分)
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
  self.task_id = '05db4166-de34-4d4b-9078-6e672b53bb21'
  self.title = '预订境外随身WiFi（中国香港、1台、5天、选最便宜）'
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
      task: "预订WiFi: 1台、5天、选最便宜的、填地址和日期",
      rental_days: @rental_days,
      quantity: @quantity,
      hint: "地区选项: 中国香港(13元起)、欧洲5国通用(20元)、欧洲6国通用5G(35元)、欧洲8国通用(25元)、欧洲10国通用(30元)。对比后选最便宜13元/天的。租赁: 1台×5天+押金500=565元。取件: 7天后、北京市朝阳区建国路118号、邮寄。联系人: 张三/13800138000",
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
      expected_price = wifi.daily_price * @rental_days * @quantity + 500
      actual_price = @internet_order.total_price
      
      expect(actual_price).to eq(expected_price),
        "订单价格错误。期望: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台 + 500元押金），实际: #{actual_price}元"
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
  
  # 模拟 AI Agent 执行（用于开发测试）
  def simulate
    puts "🤖 模拟预订流程："
    puts "1. 查询所有WiFi..."
    wifis = InternetWifi.where(data_version: 0)
    puts "   找到 #{wifis.count} 个WiFi产品"
    
    puts "2. 对比价格..."
    cheapest_wifi = wifis.min_by(&:daily_price)
    puts "   最便宜: #{cheapest_wifi.name}（#{cheapest_wifi.daily_price}元/天）"
    
    puts "3. 创建订单..."
    start_date = Date.current + 7.days
    end_date = start_date + (@rental_days - 1).days
    
    # 创建测试用户（如果不存在）
    user = User.find_or_create_by!(email: 'test@example.com') do |u|
      u.password = 'password123'
      u.data_version = 999
    end
    
    order = InternetOrder.create!(
      user: user,
      order_type: 'wifi',
      region: cheapest_wifi.region,
      orderable: cheapest_wifi,
      quantity: @quantity,
      total_price: cheapest_wifi.daily_price * @rental_days * @quantity + 500,
      status: 'pending',
      rental_info: {
        start_date: start_date.to_s,
        end_date: end_date.to_s,
        rental_days: @rental_days,
        unit_price: cheapest_wifi.daily_price
      },
      delivery_info: {
        address: "北京市朝阳区建国路118号",
        method: "mail"
      },
      contact_info: {
        name: "张三",
        phone: "13800138000"
      },
      data_version: 999
    )
    
    puts "✅ 订单创建成功！ID: #{order.id}, 总价: #{order.total_price}元"
  end
end