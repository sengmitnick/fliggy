# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 李四要去韩国3天，帮他买一张3天有效期、共5GB流量的SIM卡，邮寄到上海浦东
# 
# 任务描述:
#   Agent 需要在系统中搜索韩国地区的SIM卡，
#   找到有效期为3天且总流量为共5GB的产品，购买数量1张并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 订单类型正确（SIM卡） (15分)
#   - 地区正确（韩国） (15分)
#   - 有效期正确（3天） (15分)
#   - 流量正确（共5GB） (15分)
#   - 购买数量正确（1张） (25分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_korea_sim_3day/prepare
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V055BookKoreaSim3dayValidator < BaseValidator
    self.validator_id = 'v055_book_korea_sim_3day_validator'
    self.task_id = '6bc431af-a23f-422a-b4cf-17d17ab01d20'
    self.title = '帮李四买韩国3天共5GB流量SIM卡（买1张邮寄到上海浦东）'
    self.description = '李四要去韩国3天，帮他买一张3天有效期、共5GB流量的SIM卡，邮寄到上海浦东'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      @region = '韩国'
      @validity_days = 3
      @data_limit_keyword = '共5GB'  # 实际数据格式: "共5GB"
      @quantity = 1
    
      # 预查询用户和收货地址（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @default_address = user.addresses.find_by!(name: '李四', data_version: 0)
      @expected_name = @default_address.name
      @expected_phone = @default_address.phone
      @expected_province = @default_address.province
      @expected_city = @default_address.city
    
      # 查找符合条件的SIM卡（注意：查询基线数据 data_version=0）
      matching_sim_cards = InternetSimCard.where(
        region: @region,
        validity_days: @validity_days,
        data_version: 0
      ).where('data_limit LIKE ?', "%#{@data_limit_keyword}%")
    
      @matching_count = matching_sim_cards.count
    
      # 返回给 Agent 的任务信息
      {
        task: "请购买一张韩国3天共5GB流量的SIM卡（数量1张，邮寄到上海浦东）",
        region: @region,
        validity_days: @validity_days,
        data_requirement: "共5GB",
        quantity: @quantity,
        delivery_method: 'mail',
        recipient: "李四（#{@expected_phone}）",
        address: "#{@expected_province}#{@expected_city}#{@default_address.district}",
        hint: "系统中有多款SIM卡可选，请找到符合要求的产品。SIM卡必须邮寄",
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
    
      # 断言2: 订单类型正确（SIM卡）
      add_assertion "订单类型正确（SIM卡）", weight: 10 do
        expect(@order.order_type).to eq('sim_card'),
          "订单类型不正确。预期: sim_card, 实际: #{@order.order_type}"
      end
    
      # 断言3: 地区正确
      add_assertion "地区正确（韩国）", weight: 10 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 有效期正确（3天）
      add_assertion "有效期正确（3天）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.validity_days).to eq(@validity_days),
          "有效期不正确。预期: #{@validity_days}天, 实际: #{sim_card.validity_days}天"
      end
    
      # 断言5: 流量正确（包含"共5GB"关键词）
      add_assertion "流量正确（共5GB）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.data_limit).to include(@data_limit_keyword),
          "流量不符合要求。预期包含: #{@data_limit_keyword}, 实际: #{sim_card.data_limit}"
      end
    
      # 断言6: 购买数量正确（1张）
      add_assertion "购买数量正确（1张）", weight: 15 do
        expect(@order.quantity).to eq(@quantity),
          "购买数量不正确。预期: #{@quantity}张, 实际: #{@order.quantity}张"
      end
    
      # 断言7: 收货地址正确（邮寄方式+姓名+电话+地址省市）
      add_assertion "收货地址正确（邮寄到上海浦东李四处）", weight: 25 do
        expect(@order.delivery_method).to eq('mail'),
          "配送方式不正确。预期: mail（邮寄），实际: #{@order.delivery_method}"
        
        contact_info = JSON.parse(@order.contact_info)
        expect(contact_info['name']).to eq(@expected_name),
          "收件人姓名不正确。预期: #{@expected_name}, 实际: #{contact_info['name']}"
        expect(contact_info['phone']).to eq(@expected_phone),
          "收件人电话不正确。预期: #{@expected_phone}, 实际: #{contact_info['phone']}"
        expect(contact_info['address']).to include(@expected_province, @expected_city),
          "收货地址不正确。预期包含: #{@expected_province}#{@expected_city}, 实际: #{contact_info['address']}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        region: @region,
        validity_days: @validity_days,
        data_limit_keyword: @data_limit_keyword,
        quantity: @quantity,
        matching_count: @matching_count,
        expected_name: @expected_name,
        expected_phone: @expected_phone,
        expected_province: @expected_province,
        expected_city: @expected_city
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @region = data['region']
      @validity_days = data['validity_days']
      @data_limit_keyword = data['data_limit_keyword']
      @quantity = data['quantity']
      @matching_count = data['matching_count']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_province = data['expected_province']
      @expected_city = data['expected_city']
    end
  
    # 模拟 AI Agent 操作：购买韩国3天共5GB流量SIM卡
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找收货地址（从 prepare 预查询的数据）
      default_address = user.addresses.find_by!(name: '李四', data_version: 0)
      full_address = "#{default_address.province}#{default_address.city}#{default_address.district}#{default_address.detail}"
    
      # 3. 查找符合条件的SIM卡
      matching_sim_cards = InternetSimCard.where(
        region: @region,
        validity_days: @validity_days,
        data_version: 0
      ).where('data_limit LIKE ?', "%#{@data_limit_keyword}%")
    
      # 随机选择一个
      target_sim_card = matching_sim_cards.sample
    
      # 4. 创建订单（使用真实地址）
      order = InternetOrder.create!(
        orderable: target_sim_card,
        user_id: user.id,
        order_type: 'sim_card',
        region: @region,
        quantity: 1,
        rental_info: { validity_days: @validity_days }.to_json,
        total_price: target_sim_card.price,
        delivery_method: 'mail',
        contact_info: {
          name: default_address.name,
          phone: default_address.phone,
          address: full_address
        }.to_json,
        status: 'pending',
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_internet_order',
        order_id: order.id,
        sim_card_name: target_sim_card.name,
        validity_days: target_sim_card.validity_days,
        data_limit: target_sim_card.data_limit,
        price: target_sim_card.price,
        user_email: user.email
      }
    end
    end
end
