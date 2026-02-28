# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给王芳搜索美国WiFi租赁服务，选择5G高速版并成功创建7天租赁订单，14天后广州天河自取
# 
# 任务描述:
#   Agent 需要在系统中搜索美国地区的WiFi设备，
#   选择5G高速版（42元/天），租用1台设备共7天并成功创建订单
# 
# 租赁参数:
#   地区: 美国
#   产品: 美国随身WiFi·5G高速（42元/天）
#   租用1台，租期7天，14天后取件
#   自取地址: 广州市天河区
#   联系人: 王芳
#   总价: 42×7×1+500=794元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（wifi） (10分)
#   - 地区正确（美国） (10分)
#   - 选择了美国5G高速WiFi (20分)
#   - 租赁天数正确（7天）、总价正确（794元含押金） (20分)
#   - 自取点和联系人信息正确（广州天河，王芳） (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_usa_wifi_5g/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V063BookUsaWifi5gValidator < BaseValidator
    self.validator_id = 'v063_book_usa_wifi_5g_validator'
    self.task_id = 'fa80f73a-a50e-42f5-aa04-ff5acb84b351'
    self.title = '给王芳搜索美国WiFi租赁服务，选择5G高速版并成功创建7天租赁订单，14天后广州天河自取'
    self.description = '搜索美国WiFi租赁服务，选择5G高速版并成功创建7天租赁订单，14天后广州天河自取'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @region = '美国'
      @rental_days = 7
      @quantity = 1
      @wifi_keyword = '5G高速'
    
      # 查找符合条件的WiFi设备（注意：查询基线数据 data_version=0）
      matching_wifis = InternetWifi.where(
        region: @region,
        data_version: 0
      ).where('name LIKE ?', "%#{@wifi_keyword}%")
    
      @matching_count = matching_wifis.count
    
      # 查询联系人和自取地址
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @contact = user.contacts.find_by!(name: '王芳', data_version: 0)
      @expected_name = @contact.name
      @expected_phone = @contact.phone
      @pickup_location = PickupLocation.find_by!(
        city: '广州',
        district: '天河区',
        data_version: 0
      )
      @pickup_address = @pickup_location.full_info
    
      # 返回给 Agent 的任务信息
      {
        task: "给王芳预订美国5G高速WiFi（租1台用7天），14天后广州天河自取",
        region: @region,
        rental_days: @rental_days,
        quantity: @quantity,
        wifi_type: @wifi_keyword,
        delivery_method: 'pickup',
        contact_person: "#{@expected_name}（#{@expected_phone}）",
        hint: "美国有多款WiFi可选，选择5G高速版（42元/天）。租赁: 1台×7天+押金500=794元。取件: 14天后、广州天河、自取",
        matching_count: @matching_count,
        pickup_location: @pickup_address
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（使用data_version隔离会话）
      add_assertion "订单已创建", weight: 20 do
        @order = InternetOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到任何境外上网订单记录（data_version: #{@data_version}）"
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确（WiFi）
      add_assertion "订单类型正确（wifi）", weight: 10 do
        expect(@order.order_type).to eq('wifi'),
          "订单类型不正确。预期: wifi, 实际: #{@order.order_type}"
      end
    
      # 断言3: 地区正确
      add_assertion "地区正确（美国）", weight: 10 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 选择了美国5G高速WiFi
      add_assertion "选择了美国5G高速WiFi", weight: 20 do
        wifi = @order.orderable
        expect(wifi).not_to be_nil, "未选择具体的WiFi产品"
        expect(wifi.region).to eq(@region), "WiFi地区不匹配"
        expect(wifi.name).to include(@wifi_keyword),
          "未选择5G高速。预期包含: #{@wifi_keyword}, 实际: #{wifi.name}"
      end
    
      # 断言5: 租赁天数和总价正确
      add_assertion "租赁天数正确（7天）、总价正确（794元含押金）", weight: 20 do
        wifi = @order.orderable
        expected_price = wifi.daily_price * @rental_days * @quantity + 500
      
        rental_info = @order.rental_info.is_a?(String) ? (JSON.parse(@order.rental_info) rescue {}) : (@order.rental_info || {})
        actual_days = (rental_info['rental_days'] || rental_info['days']).to_i
      
        expect(actual_days).to eq(@rental_days),
          "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
      
        expect(@order.total_price).to eq(expected_price),
          "总价不正确。预期: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台 + 500元押金），实际: #{@order.total_price}元"
      end
    
      # 断言6: 自取点和联系人信息正确（广州天河，王芳）
      add_assertion "自取点和联系人信息正确（广州天河，#{@expected_name}）", weight: 20 do
        expect(@order.delivery_method).to eq('pickup'),
          "配送方式不正确。预期: pickup（自取），实际: #{@order.delivery_method}"
        
        # 支持Hash（Rails嵌套属性）和JSON字符串两种格式
        contact_info = @order.contact_info
        contact_info = JSON.parse(contact_info) if contact_info.is_a?(String)
        
        actual_name = contact_info['name'] || contact_info[:name]
        actual_phone = contact_info['phone'] || contact_info[:phone]
        
        expect(actual_name).to eq(@expected_name),
          "联系人姓名不正确。预期: #{@expected_name}, 实际: #{actual_name}"
        expect(actual_phone).to eq(@expected_phone),
          "联系人电话不正确。预期: #{@expected_phone}, 实际: #{actual_phone}"
        
        # 支持Hash和JSON字符串两种格式
        delivery_info = @order.delivery_info
        delivery_info = JSON.parse(delivery_info) if delivery_info.is_a?(String)
        
        actual_address = delivery_info['address'] || delivery_info[:address]
        expect(actual_address).to include('广州', '天河'),
          "自取地址不正确。预期包含: 广州天河, 实际: #{actual_address}"
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
        expected_name: @expected_name,
        expected_phone: @expected_phone,
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
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @pickup_address = data['pickup_address']
    end
  
    # 模拟 AI Agent 操作：预订美国5G WiFi
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
      start_date = Date.current + 14.days
      end_date = start_date + (@rental_days - 1).days
    
      # 4. 查找联系人和自取地址
      contact = user.contacts.find_by!(name: '王芳', data_version: 0)
      pickup_location = PickupLocation.find_by!(
        city: '广州',
        district: '天河区',
        data_version: 0
      )
      pickup_address = pickup_location.full_info
    
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
          address: pickup_address,
          method: "pickup"
        }.to_json,
        contact_info: {
          name: contact.name,
          phone: contact.phone,
          address: pickup_address
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