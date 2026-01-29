# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 购买新加坡7天无限流量SIM卡（数量1张）
# 
# 任务描述:
#   Agent 需要在系统中搜索新加坡地区的SIM卡，
#   找到有效期为7天且流量无限的产品，购买数量1张并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 订单类型正确（SIM卡） (15分)
#   - 地区正确（新加坡） (15分)
#   - 有效期正确（7天） (15分)
#   - 流量正确（无限） (15分)
#   - 购买数量正确（1张） (25分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_singapore_sim_7day/prepare
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V057BookSingaporeSim7dayValidator < BaseValidator
  self.validator_id = 'v057_book_singapore_sim_7day_validator'
  self.task_id = '24205fa9-acae-42c0-ae53-fae2238238d2'
  self.title = '购买新加坡7天无限流量SIM卡（数量1张）'
  self.description = '搜索新加坡地区的SIM卡，找到7天有效期且流量无限的产品并购买1张'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    @region = '新加坡'
    @validity_days = 7
    @data_limit_keyword = '无限'
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
      task: "请购买一张新加坡7天无限流量的SIM卡（数量1张）",
      region: @region,
      validity_days: @validity_days,
      data_requirement: "无限流量",
      quantity: @quantity,
      hint: "系统中有多款SIM卡可选，请找到符合要求的产品",
      matching_count: @matching_count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 15 do
      @order = InternetOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何境外上网订单记录"
    end
    
    return unless @order # 如果没有订单，后续断言无法继续
    
    # 断言2: 订单类型正确（SIM卡）
    add_assertion "订单类型正确（SIM卡）", weight: 15 do
      expect(@order.order_type).to eq('sim_card'),
        "订单类型不正确。预期: sim_card, 实际: #{@order.order_type}"
    end
    
    # 断言3: 地区正确
    add_assertion "地区正确（新加坡）", weight: 15 do
      expect(@order.region).to eq(@region),
        "地区不正确。预期: #{@region}, 实际: #{@order.region}"
    end
    
    # 断言4: 有效期正确（7天）
    add_assertion "有效期正确（7天）", weight: 15 do
      sim_card = @order.orderable
      expect(sim_card.validity_days).to eq(@validity_days),
        "有效期不正确。预期: #{@validity_days}天, 实际: #{sim_card.validity_days}天"
    end
    
    # 断言5: 流量正确（包含"无限"关键词）
    add_assertion "流量正确（无限）", weight: 15 do
      sim_card = @order.orderable
      expect(sim_card.data_limit).to include(@data_limit_keyword),
        "流量不符合要求。预期包含: #{@data_limit_keyword}, 实际: #{sim_card.data_limit}"
    end
    
    # 断言6: 购买数量正确（1张）
    add_assertion "购买数量正确（1张）", weight: 25 do
      expect(@order.quantity).to eq(@quantity),
        "购买数量不正确。预期: #{@quantity}张, 实际: #{@order.quantity}张"
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
  
  # 模拟 AI Agent 操作：购买新加坡7天无限流量SIM卡
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的SIM卡
    matching_sim_cards = InternetSimCard.where(
      region: @region,
      validity_days: @validity_days,
      data_version: 0
    ).where('data_limit LIKE ?', "%#{@data_limit_keyword}%")
    
    # 随机选择一个
    target_sim_card = matching_sim_cards.sample
    
    # 3. 创建订单（固定参数）
    order = InternetOrder.create!(
      orderable: target_sim_card,
      user_id: user.id,
      order_type: 'sim_card',
      region: @region,
      quantity: 1,
      rental_info: { validity_days: @validity_days }.to_json,
      total_price: target_sim_card.price,
      delivery_method: 'mail',
      contact_info: { name: '张三', phone: '13800138000', address: '测试地址' }.to_json,
      status: 'pending'
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