# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例52: 帮张三预订去中国香港的随身WiFi（7天后取，租5天，选1台，北京朝阳区自取）
# 
# 任务描述:
#   张三下周要去中国香港出差5天，需要租一台随身WiFi。
#   帮他从可用的WiFi产品中选最便宜的，7天后（2026-03-06）到北京朝阳区自取，租期5天（2026-03-06 至 2026-03-10）。
#   联系人填张三。
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 订单类型=wifi (10分)
#   - 选了具体WiFi产品 (10分)
#   - 选了最便宜13元/天的香港4G·500MB (20分)
#   - 租赁天数正确（5天）(5分)
#   - 数量正确（1台）(5分)
#   - 取件地址正确（北京市朝阳区建国路118号）(5分)
#   - 取件方式正确（邮寄）(5分)
#   - 联系人信息正确（张三 13800138000）(5分)
#   - 总价=565元（含500元押金）(20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v052_book_internet_wifi_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V052BookInternetWifiValidator < BaseValidator
    self.validator_id = 'v052_book_internet_wifi_validator'
    self.task_id = '05db4166-de34-4d4b-9078-6e672b53bb21'
    self.title = '帮张三预订去中国香港的随身WiFi（7天后取，租5天，选1台，选最便宜，北京朝阳区自取）'
    self.description = '帮张三预订去中国香港的随身WiFi，从可用产品中选最便宜的，7天后取件，租5天，选1台，北京朝阳区自取'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @rental_days = 5  # 租赁5天
      @quantity = 1     # 1台设备
      @delivery_method = "pickup" # 取件方式：自取
      @contact_name = "张三" # 联系人
      
      # 查找北京朝阳区的自取地点
      @pickup_location = PickupLocation.find_by!(
        city: '北京',
        district: '朝阳区',
        data_version: 0
      )
    
      # 查找所有可用的WiFi产品（注意：查询基线数据 data_version=0）
      @available_wifis = InternetWifi.where(data_version: 0)
    
      # 返回给 Agent 的任务信息
      {
        task: "帮张三订去中国香港的随身WiFi，租1台用5天，选7天后取件（具体日期：#{(Date.current + 7.days).strftime('%Y-%m-%d')} 至 #{(Date.current + 11.days).strftime('%Y-%m-%d')}），选最便宜的",
        rental_period: "#{(Date.current + 7.days).strftime('%Y-%m-%d')} 至 #{(Date.current + 11.days).strftime('%Y-%m-%d')}（共#{@rental_days}天）",
        pickup_date: (Date.current + 7.days).strftime('%Y-%m-%d'),
        return_date: (Date.current + 11.days).strftime('%Y-%m-%d'),
        rental_days: @rental_days,
        quantity: @quantity,
        delivery_method: "自取",
        contact_name: @contact_name,
        pickup_location: {
          city: @pickup_location.city,
          district: @pickup_location.district,
          detail: @pickup_location.detail
        },
        available_wifis_count: @available_wifis.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（使用data_version隔离会话）
      add_assertion "订单已创建", weight: 15 do
        @internet_order = InternetOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@internet_order).not_to be_nil, "未找到任何境外上网订单记录（data_version: #{@data_version}）"
      end
    
      return unless @internet_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确
      add_assertion "订单类型正确（wifi）", weight: 10 do
        actual_type = @internet_order.order_type
        expect(actual_type).to eq('wifi'),
          "订单类型错误。期望: wifi, 实际: #{actual_type}"
      end
    
      # 断言3: 选择了具体的WiFi产品
      add_assertion "选择了具体的WiFi产品", weight: 10 do
        expect(@internet_order.orderable_type).to eq('InternetWifi'), "未选择WiFi产品（orderable_type错误）"
        expect(@internet_order.orderable_id).not_to be_nil, "未选择具体的WiFi产品（orderable_id为空）"
        expect(@internet_order.orderable).not_to be_nil, "WiFi产品记录不存在"
      end
    
      # 断言4: 选择了最便宜的WiFi（核心评分项）
      add_assertion "选择了最便宜的WiFi（中国香港地区）", weight: 20 do
        # 先筛选中国香港地区的WiFi
        hk_wifis = InternetWifi.where(data_version: 0, region: "中国香港")
      
        # 找到香港地区日租金最低的
        cheapest_wifi = hk_wifis.min_by(&:daily_price)
        actual_price = @internet_order.orderable.daily_price
        cheapest_price = cheapest_wifi.daily_price
      
        expect(@internet_order.orderable_id).to eq(cheapest_wifi.id),
          "未选择中国香港地区最便宜的WiFi。" \
          "应选: #{cheapest_wifi.name}（#{cheapest_price}元/天，中国香港），" \
          "实际选择: #{@internet_order.orderable.name}（#{actual_price}元/天，#{@internet_order.orderable.region}）"
      end
    
      # 断言5: 租赁天数正确
      add_assertion "租赁天数正确（5天）", weight: 5 do
        actual_days = @internet_order.rental_info&.dig('rental_days') || @internet_order.rental_info&.dig(:rental_days)
        # 容错处理：支持字符串和整数
        actual_days = actual_days.to_i if actual_days.is_a?(String)
        expect(actual_days).to eq(@rental_days),
          "租赁天数错误。期望: #{@rental_days}天, 实际: #{actual_days}天"
      end
    
      # 断言6: 数量正确
      add_assertion "数量正确（1台）", weight: 5 do
        expect(@internet_order.quantity).to eq(@quantity),
          "数量错误。期望: #{@quantity}台, 实际: #{@internet_order.quantity}台"
      end
    
      # 断言7: 取件地点正确（北京朝阳区）
      add_assertion "取件地点正确（北京朝阳区）", weight: 5 do
        # 检查 rental_info 中的 pickup_location 字段
        rental_info = @internet_order.rental_info.is_a?(String) ? (JSON.parse(@internet_order.rental_info) rescue {}) : (@internet_order.rental_info || {})
        actual_pickup_location = rental_info['pickup_location'] || rental_info[:pickup_location]
        
        # 容错处理：支持字符串、Hash或 PickupLocation 对象
        location_str = case actual_pickup_location
                       when String
                         actual_pickup_location
                       when Hash
                         actual_pickup_location.values.join(' ')
                       else
                         actual_pickup_location.to_s
                       end
        
        expect(location_str).to include('北京'),
          "取件地点应该在北京。实际: #{location_str}"
        expect(location_str).to include('朝阳区'),
          "取件地点应该在朝阳区。实际: #{location_str}"
      end
    
      # 断言8: 取件方式正确
      add_assertion "取件方式正确（自取）", weight: 5 do
        # 可能存储在 delivery_method 中
        actual_method = @internet_order.delivery_method
        expect(actual_method).to eq(@delivery_method),
          "取件方式错误。期望: #{@delivery_method}（自取）, 实际: #{actual_method}"
      end
    
      # 断言9: 联系人信息来自demo_user（张三）
      add_assertion "联系人信息来自demo_user（张三 13800138000）", weight: 5 do
        actual_name = @internet_order.contact_info&.dig('name') || @internet_order.contact_info&.dig(:name)
        actual_phone = @internet_order.contact_info&.dig('phone') || @internet_order.contact_info&.dig(:phone)
        
        # 验证联系人姓名来自demo_user的联系人
        expect(actual_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（来自demo_user.contacts）, 实际: #{actual_name}"
        
        # 验证电话号码来自demo_user的联系人
        expect(actual_phone).to eq('13800138000'),
          "联系人电话错误。期望: 13800138000（来自demo_user.contacts），实际: #{actual_phone}"
      end
    
      # 断言10: 订单价格正确
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
        quantity: @quantity,
        delivery_method: @delivery_method,
        contact_name: @contact_name,
        pickup_location_id: @pickup_location&.id
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @rental_days = data['rental_days']
      @quantity = data['quantity']
      @delivery_method = data['delivery_method']
      @contact_name = data['contact_name']
      
      # 恢复自取地点
      if data['pickup_location_id']
        @pickup_location = PickupLocation.find_by(id: data['pickup_location_id'], data_version: 0)
      end
    
      # 重新加载可用WiFi列表
      @available_wifis = InternetWifi.where(data_version: 0)
    end
  
    # 模拟 AI Agent 执行（用于开发测试）
    def simulate
      wifis = InternetWifi.where(data_version: 0)
      hk_wifis = wifis.where(region: "中国香港")
      cheapest_wifi = hk_wifis.min_by(&:daily_price)
    
      # 使用Date.current避免时区问题
      start_date = Date.current + 7.days
      end_date = start_date + (@rental_days - 1).days
    
      # 使用 demo_user (demo@travel01.com)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 从 demo_user 的联系人中获取张三
      contact = user.contacts.find_by!(name: '张三', data_version: 0)
      
      # 获取北京朝阳区的自取地点
      pickup_location = PickupLocation.find_by!(
        city: '北京',
        district: '朝阳区',
        data_version: 0
      )
    
      order = InternetOrder.create!(
        user: user,
        order_type: 'wifi',
        region: cheapest_wifi.region,
        orderable: cheapest_wifi,
        quantity: @quantity,
        total_price: cheapest_wifi.daily_price * @rental_days * @quantity + 500,
        status: 'pending',
        delivery_method: 'pickup',
        rental_info: {
          start_date: start_date.to_s,
          end_date: end_date.to_s,
          rental_days: @rental_days,
          unit_price: cheapest_wifi.daily_price,
          pickup_location: pickup_location.full_info
        },
        contact_info: {
          name: contact.name,
          phone: contact.phone
        },
        data_version: @data_version
      )
    end
    end
end
