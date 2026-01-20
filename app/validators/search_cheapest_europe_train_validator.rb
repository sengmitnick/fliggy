# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例12: 搜索明天欧洲境内最便宜的火车票
# 
# 任务描述:
#   Agent 需要搜索明天所有欧洲境内的火车票，
#   找出价格最便宜的班次并成功创建订单
# 
# 评分标准:
#   - 搜索到了所有欧洲班次 (20分)
#   - 正确识别最便宜的班次 (40分)
#   - 成功创建订单 (20分)
#   - 订单信息准确 (20分)
# 
# 难点:
#   - 需要对比所有欧洲路线的价格
#   - 需要找出全局最低价格
#   - 需要理解"欧洲境内"概念（region=europe）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_cheapest_europe_train/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchCheapestEuropeTrainValidator < BaseValidator
  self.validator_id = 'search_cheapest_europe_train'
  self.title = '搜索并预订明天欧洲境内最便宜的火车票'
  self.description = '搜索明天所有欧洲境内的火车票，找出价格最便宜的班次并完成预订'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    @region = 'europe'
    @target_date = Date.current + 1.day  # 明天
    
    # 查找所有欧洲班次（注意：查询基线数据）
    europe_trains = AbroadTicket.where(
      region: @region,
      ticket_type: 'train',
      departure_date: @target_date,
      data_version: 0
    )
    
    # 找出最便宜的价格
    @cheapest_price = europe_trains.minimum(:price)
    @total_trains = europe_trains.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索明天所有欧洲境内的火车票，找出价格最便宜的班次并预订",
      region: @region,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "需要对比所有欧洲路线的价格，找出最低价",
      total_trains: @total_trains,
      price_range: "#{europe_trains.minimum(:price).to_f.round(2)} - #{europe_trains.maximum(:price).to_f.round(2)} 元"
    }
  end
  
  # 验证阶段：检查是否找到并预订了最便宜的班次
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @order = AbroadTicketOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何境外票务订单记录"
    end
    
    return unless @order
    
    # 断言2: 地区正确（欧洲）
    add_assertion "地区正确（欧洲）", weight: 10 do
      expect(@order.abroad_ticket.region).to eq(@region),
        "地区不正确。预期: #{@region}, 实际: #{@order.abroad_ticket.region}"
    end
    
    # 断言3: 日期正确
    add_assertion "出发日期正确（明天）", weight: 10 do
      expect(@order.abroad_ticket.departure_date).to eq(@target_date),
        "出发日期不正确。预期: #{@target_date}, 实际: #{@order.abroad_ticket.departure_date}"
    end
    
    # 断言4: 选择了最便宜的班次（核心评分）
    add_assertion "选择了最便宜的班次", weight: 40 do
      # 重新查询所有欧洲班次找出最低价
      all_europe_trains = AbroadTicket.where(
        region: @region,
        ticket_type: 'train',
        departure_date: @target_date,
        data_version: 0
      )
      
      min_price = all_europe_trains.minimum(:price)
      booked_price = @order.abroad_ticket.price
      
      # 允许0.01的浮点误差
      expect(booked_price).to be_within(0.01).of(min_price),
        "未选择最便宜的班次。最低价: ¥#{min_price}, 实际预订: ¥#{booked_price}"
    end
    
    # 断言5: 订单金额准确
    add_assertion "订单金额准确", weight: 20 do
      expected_price = @order.abroad_ticket.price
      
      expect(@order.total_price).to be_within(0.01).of(expected_price),
        "订单金额不正确。预期: ¥#{expected_price}, 实际: ¥#{@order.total_price}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      region: @region,
      target_date: @target_date.to_s,
      cheapest_price: @cheapest_price,
      total_trains: @total_trains
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @region = data['region']
    @target_date = Date.parse(data['target_date'])
    @cheapest_price = data['cheapest_price']
    @total_trains = data['total_trains']
  end
  
  # 模拟 AI Agent 操作：搜索欧洲最便宜的火车票并预订
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找所有欧洲班次
    all_europe_trains = AbroadTicket.where(
      region: @region,
      ticket_type: 'train',
      departure_date: @target_date,
      data_version: 0
    )
    
    # 3. 找出最便宜的
    target_train = all_europe_trains.order(:price).first
    
    # 4. 创建订单（固定参数）
    order = AbroadTicketOrder.create!(
      abroad_ticket_id: target_train.id,
      user_id: user.id,
      passenger_name: '张三',
      contact_phone: '13800138000',
      contact_email: 'demo@travel01.com',
      passenger_type: 'adult',
      seat_category: 'standard',
      total_price: target_train.price,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_abroad_ticket_order',
      order_id: order.id,
      route: "#{target_train.origin} → #{target_train.destination}",
      departure_date: target_train.departure_date.to_s,
      time_slot: "#{target_train.time_slot_start} - #{target_train.time_slot_end}",
      price: target_train.price,
      user_email: user.email
    }
  end
end
