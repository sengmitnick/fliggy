# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 李四要去泰国3天，帮他租一台随身WiFi，选4G经济版（最便宜），7天后上海浦东自取
# 
# 任务描述:
#   Agent 需要在系统中搜索泰国地区的WiFi设备，
#   选择4G经济版（9元/天），租用1台设备共3天并成功创建订单
# 
# 租赁参数:
#   地区: 泰国
#   产品: 泰国随身WiFi·4G经济版（9元/天）
#   租用1台，租期3天，7天后取件
#   取件地址: 上海市浦东新区世纪大道1000号
#   联系人: 李四 13900139000
#   总价: 9×3×1+500=527元
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 订单类型正确（wifi） (10分)
#   - 地区正确（泰国） (10分)
#   - 选择了泰国4G经济版WiFi (10分)
#   - 租赁天数正确（3天）、总价正确（527元含押金） (25分)
#   - 自取点和联系人信息正确（上海浦东，李四） (15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_thailand_wifi_3day/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V059BookThailandWifi3dayValidator < BaseValidator
    self.validator_id = 'v059_book_thailand_wifi_3day_validator'
    self.task_id = '6b2013cb-010e-4832-8605-40a394c83748'
    self.title = '李四要去泰国3天，帮他租一台随身WiFi，选4G经济版（最便宜），7天后上海浦东自取'
    self.description = '李四要去泰国3天，帮他租一台随身WiFi，选4G经济版（最便宜），7天后上海浦东自取'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @region = '泰国'
      @rental_days = 3
      @quantity = 1
      @wifi_keyword = '4G经济版'
    
      # 预查询用户和联系人（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @contact = user.contacts.find_by!(name: '李四', data_version: 0)
      @expected_contact_name = @contact.name
      @expected_contact_phone = @contact.phone
      @pickup_address = '上海市浦东新区世纪大道1000号'
    
      # 查找符合条件的WiFi设备（注意：查询基线数据 data_version=0）
      matching_wifis = InternetWifi.where(
        region: @region,
        data_version: 0
      ).where('name LIKE ?', "%#{@wifi_keyword}%")
    
      @matching_count = matching_wifis.count
    
      # 返回给 Agent 的任务信息
      {
        task: "请预订一台泰国4G经济版WiFi，租用3天，自取点上海浦东",
        region: @region,
        rental_days: @rental_days,
        quantity: @quantity,
        wifi_type: @wifi_keyword,
        delivery_method: 'pickup',
        pickup_location: '上海浦东',
        contact_person: "#{@expected_contact_name}（#{@expected_contact_phone}）",
        hint: "泰国有多款WiFi可选，选择4G经济版（9元/天）。租赁: 1台×3天+押金500=527元。取件: 7天后、上海市浦东新区世纪大道1000号、自取。联系人: 李四/#{@expected_contact_phone}",
        matching_count: @matching_count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 订单已创建 (30分)
      add_assertion "订单已创建", weight: 30 do
        @order = InternetOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到任何境外上网订单记录"
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确（WiFi）
      add_assertion "订单类型正确（wifi）", weight: 10 do
        expect(@order.order_type).to eq('wifi'),
          "订单类型不正确。预期: wifi, 实际: #{@order.order_type}"
      end
    
      # 断言3: 地区正确
      add_assertion "地区正确（泰国）", weight: 10 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 选择了泰国4G经济版WiFi
      add_assertion "选择了泰国4G经济版WiFi", weight: 10 do
        wifi = @order.orderable
        expect(wifi).not_to be_nil, "未选择具体的WiFi产品"
        expect(wifi.region).to eq(@region), "WiFi地区不匹配"
        expect(wifi.name).to include(@wifi_keyword),
          "未选择4G经济版。预期包含: #{@wifi_keyword}, 实际: #{wifi.name}"
      end
    
      # 断言5: 租赁天数正确（3天）、总价正确（527元含押金） (25分)
      add_assertion "租赁天数正确（3天）、总价正确（527元含押金）", weight: 25 do
        wifi = @order.orderable
        expected_price = wifi.daily_price * @rental_days * @quantity + 500
      
        rental_info = @order.rental_info.is_a?(String) ? (JSON.parse(@order.rental_info) rescue {}) : (@order.rental_info || {})
        actual_days = (rental_info['rental_days'] || rental_info['days']).to_i
      
        expect(actual_days).to eq(@rental_days),
          "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
      
        expect(@order.total_price).to eq(expected_price),
          "总价不正确。预期: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台 + 500元押金），实际: #{@order.total_price}元"
      end
    
      # 断言6: 自取点和联系人信息正确（上海浦东，李四） (15分)
      add_assertion "自取点和联系人信息正确（上海浦东，李四）", weight: 15 do
        expect(@order.delivery_method).to eq('pickup'),
          "配送方式不正确。预期: pickup（自取），实际: #{@order.delivery_method}"
        
        # 支持Hash（Rails嵌套属性）和JSON字符串两种格式
        contact_info = @order.contact_info
        contact_info = JSON.parse(contact_info) if contact_info.is_a?(String)
        
        actual_name = contact_info['name'] || contact_info[:name]
        actual_phone = contact_info['phone'] || contact_info[:phone]
        
        expect(actual_name).to eq(@expected_contact_name),
          "联系人姓名不正确。预期: #{@expected_contact_name}, 实际: #{actual_name}"
        expect(actual_phone).to eq(@expected_contact_phone),
          "联系人电话不正确。预期: #{@expected_contact_phone}, 实际: #{actual_phone}"
        
        # 支持Hash和JSON字符串两种格式
        delivery_info = @order.delivery_info
        delivery_info = JSON.parse(delivery_info) if delivery_info.is_a?(String)
        
        actual_address = delivery_info['address'] || delivery_info[:address]
        expect(actual_address).to include('上海', '浦东'),
          "自取地址不正确。预期包含: 上海浦东, 实际: #{actual_address}"
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
        matching_count: @matching_count,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        pickup_address: @pickup_address
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @region = data['region']
      @rental_days = data['rental_days']
      @quantity = data['quantity']
      @wifi_keyword = data['wifi_keyword']
      @matching_count = data['matching_count']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @pickup_address = data['pickup_address']
    end
  
    # 模拟 AI Agent 操作：预订泰国WiFi
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找符合条件的WiFi
      matching_wifis = InternetWifi.where(
        region: @region,
        data_version: 0
      ).where('name LIKE ?', "%#{@wifi_keyword}%")
    
      # 随机选择一个
      target_wifi = matching_wifis.sample
    
      # 3. 计算日期（使用Date.current避免时区问题）
      start_date = Date.current + 7.days
      end_date = start_date + (@rental_days - 1).days
    
      # 4. 查找联系人（从 prepare 预查询的数据）
      contact = user.contacts.find_by!(name: '李四', data_version: 0)
    
      # 5. 创建订单
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
        delivery_method: 'pickup',
        delivery_info: {
          address: @pickup_address,
          method: "pickup"
        }.to_json,
        contact_info: {
          name: contact.name,
          phone: contact.phone,
          address: @pickup_address
        }.to_json,
        status: 'pending',
        data_version: @data_version
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
end
