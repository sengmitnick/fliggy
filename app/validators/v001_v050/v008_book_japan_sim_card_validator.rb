# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三购买日本7天无限量流量SIM卡（邮寄到默认地址）
# 
# 任务描述:
#   Agent 需要在系统中搜索日本地区的SIM卡，
#   找到有效期为7天且流量为"无限量"的产品，购买1张并邮寄到张三的默认收货地址
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 订单类型正确（SIM卡） (10分)
#   - 地区正确（日本） (15分)
#   - 有效期正确（7天） (10分)
#   - 流量正确（无限量） (10分)
#   - 购买数量正确（1张） (15分)
#   - 邮寄方式和地址正确（mail + 张三北京地址） (10分)
#   - 联系人信息正确（张三 13800138000） (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_japan_sim_card/prepare
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V008BookJapanSimCardValidator < BaseValidator
    self.validator_id = 'v008_book_japan_sim_card_validator'
    self.task_id = '7a5cf48f-838f-4e29-a0e1-4dd67250b0d9'
    self.title = '给张三购买日本7天无限量流量SIM卡（邮寄到默认地址）'
    self.description = '搜索日本地区的SIM卡，找到7天有效期且流量为"无限量"的产品并购买1张，邮寄到张三的默认收货地址'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载
      # 注意：日本地区数据已在 internet_services.rb 数据包中创建
      @region = '日本'
      @validity_days = 7
      @data_limit_keyword = '无限量'  # 实际数据格式: "无限量"
      @quantity = 1
    
      # 查找符合条件的SIM卡（注意：查询基线数据 data_version=0）
      matching_sim_cards = InternetSimCard.where(
        region: @region,
        validity_days: @validity_days,
        data_version: 0
      ).where('data_limit LIKE ?', "%#{@data_limit_keyword}%")
    
      @matching_count = matching_sim_cards.count
    
      # 返回给 Agent 的任务信息
      {
        task: "请给张三购买一张日本7天无限量流量的SIM卡，邮寄到默认地址",
        region: @region,
        validity_days: @validity_days,
        data_requirement: "无限量",
        quantity: @quantity,
        recipient: "张三",
        delivery_method: "邮寄",
        hint: "系统中有多款SIM卡可选，请找到符合要求的产品并邮寄到张三的默认收货地址",
        matching_count: @matching_count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "创建了境外上网订单", weight: 20 do
        all_internet_orders = InternetOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_internet_orders).not_to be_empty, "未找到任何境外上网订单记录"
        @order = all_internet_orders.first
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确（SIM卡）
      add_assertion "订单类型正确（SIM卡）", weight: 10 do
        expect(@order.order_type).to eq('sim_card'),
          "订单类型不正确。预期: sim_card, 实际: #{@order.order_type}"
      end
    
      # 断言3: 地区正确
      add_assertion "地区正确（日本）", weight: 15 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 有效期正确（7天）
      add_assertion "有效期正确（7天）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.validity_days).to eq(@validity_days),
          "有效期不正确。预期: #{@validity_days}天, 实际: #{sim_card.validity_days}天"
      end
    
      # 断言5: 流量正确（包含"无限量"关键词）
      add_assertion "流量正确（无限量）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.data_limit).to include(@data_limit_keyword),
          "流量不符合要求。预期包含: #{@data_limit_keyword}, 实际: #{sim_card.data_limit}"
      end
    
      # 断言6: 购买数量正确（1张）
      add_assertion "购买数量正确（1张）", weight: 15 do
        expect(@order.quantity).to eq(@quantity),
          "购买数量不正确。预期: #{@quantity}张, 实际: #{@order.quantity}张"
      end
    
      # 断言7: 邮寄方式和地址正确
      add_assertion "邮寄方式和地址正确（mail + 张三北京地址）", weight: 10 do
        expect(@order.delivery_method).to eq('mail'),
          "交付方式错误。期望: mail（邮寄），实际: #{@order.delivery_method}"
        
        contact_info = JSON.parse(@order.contact_info)
        expect(contact_info['name']).to eq('张三'),
          "收货人姓名错误。期望: 张三（demo_user地址）, 实际: #{contact_info['name']}"
        expect(contact_info['address']).to include('北京'),
          "收货地址错误。期望包含: 北京（demo_user默认地址）, 实际: #{contact_info['address']}"
      end
    
      # 断言8: 联系人信息正确（来自demo_user数据）
      add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
        contact_info = JSON.parse(@order.contact_info)
        expect(contact_info['name']).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{contact_info['name']}"
        expect(contact_info['phone']).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{contact_info['phone']}"
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
        matching_count: @matching_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @region = data['region']
      @validity_days = data['validity_days']
      @data_limit_keyword = data['data_limit_keyword']
      @quantity = data['quantity']
      @matching_count = data['matching_count']
    end
  
    # 模拟 AI Agent 操作：购买日本7天无限量流量SIM卡
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找张三的默认收货地址（电话卡必须邮寄）
      default_address = user.addresses.find_by!(is_default: true, data_version: 0)
    
      # 3. 查找符合条件的SIM卡
      matching_sim_cards = InternetSimCard.where(
        region: @region,
        validity_days: @validity_days,
        data_version: 0
      ).where('data_limit LIKE ?', "%#{@data_limit_keyword}%")
    
      # 随机选择一个
      target_sim_card = matching_sim_cards.sample
    
      # 4. 创建订单（使用 demo_user 的真实地址）
      full_address = "#{default_address.province}#{default_address.city}#{default_address.district}#{default_address.detail}"
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
        status: 'pending'
      )
    
      # 5. 返回操作信息
      {
        action: 'create_internet_order',
        order_id: order.id,
        sim_card_name: target_sim_card.name,
        validity_days: target_sim_card.validity_days,
        data_limit: target_sim_card.data_limit,
        price: target_sim_card.price,
        delivery_address: full_address,
        recipient: default_address.name,
        user_email: user.email
      }
    end
    end
end
