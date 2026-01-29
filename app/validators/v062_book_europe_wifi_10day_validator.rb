# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 预订欧洲通用WiFi（欧洲10国通用、租用1台、10天后取件、共租10天）
# 
# 任务描述:
#   Agent 需要在系统中搜索欧洲地区的WiFi设备，
#   选择欧洲10国通用WiFi·豪华版（30元/天），租用1台设备共10天并成功创建订单
# 
# 租赁参数:
#   地区: 欧洲10国通用
#   产品: 欧洲10国通用WiFi·豪华版（30元/天）
#   租用1台，租期10天，10天后取件
#   取件地址: 杭州市西湖区文一西路998号
#   联系人: 孙七 13500135000
#   总价: 30×10×1+500=800元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（wifi） (15分)
#   - 地区正确（欧洲10国通用） (15分)
#   - 选择了欧洲10国通用WiFi (25分)
#   - 租赁天数正确（10天）、总价正确（800元含押金） (25分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_europe_wifi_10day/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V062BookEuropeWifi10dayValidator < BaseValidator
  self.validator_id = 'v062_book_europe_wifi_10day_validator'
  self.task_id = '6d96f11c-0653-4ae3-87b9-810157adff1f'
  self.title = '预订欧洲通用WiFi（1台、10天、欧洲10国通用）'
  self.description = '搜索欧洲WiFi租赁服务，选择欧洲10国通用WiFi·豪华版并成功创建10天租赁订单'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @region = '欧洲10国通用'
    @rental_days = 10
    @quantity = 1
    @wifi_keyword = '欧洲10国通用'
    
    # 查找符合条件的WiFi设备（注意：查询基线数据 data_version=0）
    matching_wifis = InternetWifi.where(
      region: @region,
      data_version: 0
    )
    
    @matching_count = matching_wifis.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一台欧洲10国通用WiFi，租用10天",
      region: @region,
      rental_days: @rental_days,
      quantity: @quantity,
      wifi_type: @wifi_keyword,
      hint: "欧洲有多款通用WiFi可选，选择欧洲10国通用WiFi·豪华版（30元/天）。租赁: 1台×10天+押金500=800元。取件: 10天后、杭州市西湖区文一西路998号、邮寄。联系人: 孙七/13500135000",
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
    
    # 断言2: 订单类型正确（WiFi）
    add_assertion "订单类型正确（wifi）", weight: 15 do
      expect(@order.order_type).to eq('wifi'),
        "订单类型不正确。预期: wifi, 实际: #{@order.order_type}"
    end
    
    # 断言3: 地区正确
    add_assertion "地区正确（欧洲10国通用）", weight: 15 do
      expect(@order.region).to eq(@region),
        "地区不正确。预期: #{@region}, 实际: #{@order.region}"
    end
    
    # 断言4: 选择了欧洲10国通用WiFi
    add_assertion "选择了欧洲10国通用WiFi", weight: 25 do
      wifi = @order.orderable
      expect(wifi).not_to be_nil, "未选择具体的WiFi产品"
      expect(wifi.region).to eq(@region), "WiFi地区不匹配"
      expect(wifi.name).to include(@wifi_keyword),
        "未选择欧洲10国通用WiFi。预期包含: #{@wifi_keyword}, 实际: #{wifi.name}"
    end
    
    # 断言5: 租赁天数和总价正确
    add_assertion "租赁天数正确（10天）、总价正确（800元含押金）", weight: 25 do
      wifi = @order.orderable
      expected_price = wifi.daily_price * @rental_days * @quantity + 500
      
      rental_info = JSON.parse(@order.rental_info) rescue {}
      actual_days = rental_info['rental_days']
      
      expect(actual_days).to eq(@rental_days),
        "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
      
      expect(@order.total_price).to eq(expected_price),
        "总价不正确。预期: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台 + 500元押金），实际: #{@order.total_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      region: @region,
      rental_days: @rental_days,
      quantity: @quantity,
      wifi_keyword: @wifi_keyword,
      matching_count: @matching_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @rental_days = data['rental_days']
    @quantity = data['quantity']
    @wifi_keyword = data['wifi_keyword']
    @matching_count = data['matching_count']
  end
  
  # 模拟 AI Agent 操作：预订欧洲10国通用WiFi
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的WiFi
    matching_wifis = InternetWifi.where(
      region: @region,
      data_version: 0
    )
    
    # 随机选择一个
    target_wifi = matching_wifis.sample
    
    # 3. 计算日期
    start_date = Date.current + 10.days
    end_date = start_date + (@rental_days - 1).days
    
    # 4. 创建订单
    order = InternetOrder.create!(
      orderable: target_wifi,
      user_id: user.id,
      order_type: 'wifi',
      region: @region,
      quantity: @quantity,
      rental_info: {
        start_date: start_date.to_s,
        end_date: end_date.to_s,
        rental_days: @rental_days,
        unit_price: target_wifi.daily_price
      }.to_json,
      total_price: target_wifi.daily_price * @rental_days * @quantity + 500,
      delivery_method: 'mail',
      delivery_info: {
        address: "杭州市西湖区文一西路998号",
        method: "mail"
      }.to_json,
      contact_info: { name: '孙七', phone: '13500135000', address: '杭州市西湖区文一西路998号' }.to_json,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_internet_order',
      order_id: order.id,
      wifi_name: target_wifi.name,
      daily_price: target_wifi.daily_price,
      rental_days: @rental_days,
      total_price: order.total_price,
      user_email: user.email
    }
  end
end