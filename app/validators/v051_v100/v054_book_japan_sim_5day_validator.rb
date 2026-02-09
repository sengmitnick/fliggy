# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 购买日本5天共10GB流量SIM卡（数量1张）
# 
# 任务描述:
#   Agent 需要在系统中搜索日本地区的SIM卡，
#   找到有效期为5天且总流量为共10GB的产品，购买数量1张并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 订单类型正确（SIM卡） (10分)
#   - 地区正确（日本） (10分)
#   - 有效期正确（5天） (10分)
#   - 流量正确（共10GB） (10分)
#   - 购买数量正确（1张） (20分)
#   - 收货地址正确（张三的北京地址） (25分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_japan_sim_5day/prepare
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V054BookJapanSim5dayValidator < BaseValidator
    self.validator_id = 'v054_book_japan_sim_5day_validator'
    self.task_id = 'f3339f0c-cc3f-45bf-9565-315994f07e25'
    self.title = '帮张三买日本5天共10GB流量SIM卡（买1张）'
    self.description = '张三要去日本5天，帮他买一张5天有效期、共10GB流量的SIM卡'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      @region = '日本'
      @validity_days = 5
      @data_limit_keyword = '共10GB'  # 实际数据格式: "共10GB"
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
        task: "请购买一张日本5天共10GB流量的SIM卡（数量1张）",
        region: @region,
        validity_days: @validity_days,
        data_requirement: "共10GB",
        quantity: @quantity,
        hint: "系统中有多款SIM卡可选，请找到符合要求的产品",
        matching_count: @matching_count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（按地区和订单类型筛选，使用data_version隔离会话）
      add_assertion "订单已创建", weight: 15 do
        # 先按地区和订单类型筛选，避免选到其他地区的订单
        all_orders = InternetOrder
          .where(order_type: 'sim_card', region: @region)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty,
          "未找到任何#{@region}SIM卡订单记录（data_version: #{@data_version}）"
        
        @order = all_orders.first
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确（SIM卡）
      add_assertion "订单类型正确（SIM卡）", weight: 10 do
        expect(@order.order_type).to eq('sim_card'),
          "订单类型不正确。预期: sim_card, 实际: #{@order.order_type}"
      end
    
      # 断言3: 地区正确
      add_assertion "地区正确（日本）", weight: 10 do
        expect(@order.region).to eq(@region),
          "地区不正确。预期: #{@region}, 实际: #{@order.region}"
      end
    
      # 断言4: 有效期正确（5天）
      add_assertion "有效期正确（5天）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.validity_days).to eq(@validity_days),
          "有效期不正确。预期: #{@validity_days}天, 实际: #{sim_card.validity_days}天"
      end
    
      # 断言5: 流量正确（包含"共10GB"关键词）
      add_assertion "流量正确（共10GB）", weight: 10 do
        sim_card = @order.orderable
        expect(sim_card.data_limit).to include(@data_limit_keyword),
          "流量不符合要求。预期包含: #{@data_limit_keyword}, 实际: #{sim_card.data_limit}"
      end
    
      # 断言6: 购买数量正确（1张）
      add_assertion "购买数量正确（1张）", weight: 20 do
        expect(@order.quantity).to eq(@quantity),
          "购买数量不正确。预期: #{@quantity}张, 实际: #{@order.quantity}张"
      end
    
      # 断言7: 收货地址正确（张三的北京地址）
      add_assertion "收货地址正确（张三的北京地址）", weight: 25 do
        expect(@order.delivery_method).to eq('mail'),
          "交付方式错误。期望: mail（邮寄），实际: #{@order.delivery_method}"
        
        contact_info = JSON.parse(@order.contact_info)
        expect(contact_info['name']).to eq('张三'),
          "收货人姓名错误。期望: 张三, 实际: #{contact_info['name']}"
        expect(contact_info['phone']).to eq('13800138000'),
          "收货电话错误。期望: 13800138000, 实际: #{contact_info['phone']}"
        expect(contact_info['address']).to include('北京'),
          "收货地址错误。期望包含: 北京（张三的默认地址），实际: #{contact_info['address']}"
        expect(contact_info['address']).to include('朝阳区'),
          "收货地址错误。期望包含: 朝阳区（张三的默认地址），实际: #{contact_info['address']}"
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
  
    # 模拟 AI Agent 操作：购买日本5天共10GB流量SIM卡
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
    
      # 4. 创建订单（使用张三的真实地址）
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
        status: 'pending',
        data_version: @data_version
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
