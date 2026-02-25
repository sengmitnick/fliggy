# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三搜索韩国WiFi租赁服务，选择5G高速版并成功创建5天租赁订单
# 
# 任务描述:
#   Agent 需要在系统中搜索韩国地区的WiFi设备，
#   选择5G高速版（26元/天），租用1台设备共5天并成功创建订单
# 
# 租赁参数:
#   地区: 韩国
#   产品: 韩国随身WiFi·5G高速（26元/天）
#   租用1台，租期5天，3天后取件
#   总价: 26×5×1+500=630元
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（wifi） (10分)
#   - 地区正确（韩国） (10分)
#   - 选择了韩国5G高速WiFi (20分)
#   - 租赁天数正确（5天）、总价正确（630元含押金） (20分)
#   - 联系人信息正确（来自demo_user） (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_korea_wifi_5g/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V061BookKoreaWifi5gValidator < BaseValidator
    self.validator_id = 'v061_book_korea_wifi_5g_validator'
    self.task_id = 'e8212b70-653b-4752-89e7-513eb4730cf2'
    self.title = '给张三搜索韩国WiFi租赁服务，选择5G高速版并成功创建5天租赁订单'
    self.description = '搜索韩国WiFi租赁服务，选择5G高速版并成功创建5天租赁订单'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @region = '韩国'
      @rental_days = 5
      @quantity = 1
      @wifi_keyword = '5G高速'
    
      # 查找符合条件的WiFi设备（注意：查询基线数据 data_version=0）
      matching_wifis = InternetWifi.where(
        region: @region,
        data_version: 0
      ).where('name LIKE ?', "%#{@wifi_keyword}%")
    
      @matching_count = matching_wifis.count
    
      # 查询收货地址（WiFi租赁需要邮寄）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @address = user.addresses.find_by!(name: '张三', data_version: 0)
      @expected_name = @address.name
      @expected_phone = @address.phone
      @expected_address_keyword = '北京'
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三预订韩国5G高速WiFi（租1台用5天）",
        region: @region,
        rental_days: @rental_days,
        quantity: @quantity,
        wifi_type: @wifi_keyword,
        hint: "韩国有多款WiFi可选，选择5G高速版（26元/天）。租赁: 1台×5天+押金500=630元",
        matching_count: @matching_count
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
      add_assertion "地区正确（韩国）", weight: 10 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 选择了韩国5G高速WiFi
      add_assertion "选择了韩国5G高速WiFi", weight: 20 do
        wifi = @order.orderable
        expect(wifi).not_to be_nil, "未选择具体的WiFi产品"
        expect(wifi.region).to eq(@region), "WiFi地区不匹配"
        expect(wifi.name).to include(@wifi_keyword),
          "未选择5G高速。预期包含: #{@wifi_keyword}, 实际: #{wifi.name}"
      end
    
      # 断言5: 租赁天数和总价正确
      add_assertion "租赁天数正确（5天）、总价正确（630元含押金）", weight: 20 do
        wifi = @order.orderable
        expected_price = wifi.daily_price * @rental_days * @quantity + 500
      
        rental_info = @order.rental_info.is_a?(String) ? (JSON.parse(@order.rental_info) rescue {}) : (@order.rental_info || {})
        actual_days = (rental_info['rental_days'] || rental_info['days']).to_i
      
        expect(actual_days).to eq(@rental_days),
          "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
      
        expect(@order.total_price).to eq(expected_price),
          "总价不正确。预期: #{expected_price}元（#{wifi.daily_price}元/天 × #{@rental_days}天 × #{@quantity}台 + 500元押金），实际: #{@order.total_price}元"
      end
    
      # 断言6: 收货地址正确（张三的北京地址）
      add_assertion "收货地址正确（#{@expected_name}的#{@expected_address_keyword}地址）", weight: 20 do
        expect(@order.delivery_method).to eq('mail'),
          "交付方式错误。期望: mail（邮寄），实际: #{@order.delivery_method}"
        
        delivery_info = @order.delivery_info.is_a?(String) ? (JSON.parse(@order.delivery_info) rescue {}) : (@order.delivery_info || {})
        
        expect(delivery_info['name']).to eq(@expected_name),
          "收货人姓名错误。期望: #{@expected_name}, 实际: #{delivery_info['name']}"
        expect(delivery_info['phone']).to eq(@expected_phone),
          "收货电话错误。期望: #{@expected_phone}, 实际: #{delivery_info['phone']}"
        expect(delivery_info['full_address']).to include(@expected_address_keyword),
          "收货地址错误。期望包含: #{@expected_address_keyword}（#{@expected_name}的默认地址），实际: #{delivery_info['full_address']}"
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
        expected_address_keyword: @expected_address_keyword
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
      @expected_address_keyword = data['expected_address_keyword']
    end
  
    # 模拟 AI Agent 操作：预订韩国5G WiFi
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
      start_date = Date.current + 3.days
      end_date = start_date + (@rental_days - 1).days
    
      # 4. 创建订单（使用 prepare 中查询的联系人）
      full_address = [@address.province, @address.city, @address.district, @address.detail].compact.join
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
          address_id: @address.id,
          name: @expected_name,
          phone: @expected_phone,
          full_address: full_address
        }.to_json,
        contact_info: {
          name: @expected_name,
          phone: @expected_phone
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