# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三预订明天从巴黎北站到阿姆斯特丹中央车站的火车票，找出价格最便宜的班次并预订
# 
# 任务描述:
#   Agent 需要搜索明天从巴黎北站到阿姆斯特丹中央车站的火车票，
#   找出价格最便宜的班次并成功创建订单（1人出行）
# 
# 评分标准:
#   - 搜索到了正确的线路（巴黎→阿姆斯特丹） (15分)
#   - 正确识别最便宜的班次 (35分)
#   - 成功创建订单 (20分)
#   - 订单信息准确 (10分)
#   - 出行人数正确（1人） (20分)
# 
# 难点:
#   - 需要对比该线路所有时段的价格
#   - 需要找出该线路的最低价格
#   - 需要理解欧洲火车站名称（巴黎北站 Paris Nord → 阿姆斯特丹中央车站 Amsterdam Centraal）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_cheapest_europe_train/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V012SearchCheapestEuropeTrainValidator < BaseValidator
    self.validator_id = 'v012_search_cheapest_europe_train_validator'
    self.task_id = '4d893f09-9fc7-4b28-a51a-a3b529160719'
    self.title = '给张三订明天去阿姆斯特丹的火车票（选最便宜的）'
    self.description = '给张三预订明天从巴黎北站到阿姆斯特丹中央车站的火车票，找出价格最便宜的班次并预订'
    self.timeout_seconds = 300
  
    # 准备阶段：插入测试数据
    def prepare
      # 数据已经通过 load_data_pack 自动加载
      @region = 'europe'
      @origin = '巴黎北站'
      @destination = '阿姆斯特丹中央车站'
      @target_date = Date.current + 1.day  # 明天
      @passenger_count = 1  # 出行人数
    
      # 查找该线路的所有班次（注意：查询基线数据）
      route_trains = AbroadTicket.where(
        region: @region,
        ticket_type: 'train',
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      )
    
      # 找出最便宜的价格
      @cheapest_price = route_trains.minimum(:price)
      @total_trains = route_trains.count
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三订明天去阿姆斯特丹的火车票（选最便宜的）",
        task_detail: "请搜索明天从#{@origin}到#{@destination}的火车票，找出价格最便宜的班次并预订（#{@passenger_count}人出行）",
        region: @region,
        origin: @origin,
        destination: @destination,
        date: @target_date.to_s,
        date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
        passenger_count: @passenger_count,
        hint: "需要对比该线路所有时段的价格，找出最低价",
        total_trains: @total_trains,
        price_range: "#{route_trains.minimum(:price).to_f.round(2)} - #{route_trains.maximum(:price).to_f.round(2)} 元"
      }
    end
  
    # 验证阶段：检查是否找到并预订了最便宜的班次
    def verify
      # 断言1: 必须有订单创建（查询过滤核心实体：线路）
      add_assertion "创建了境外火车票订单", weight: 20 do
        all_abroad_ticket_orders = AbroadTicketOrder
          .joins(:abroad_ticket)
          .where(
            abroad_tickets: {
              origin: @origin,
              destination: @destination,
              departure_date: @target_date,
              data_version: 0
            },
            data_version: @data_version
          )
          .order(created_at: :desc)
          .to_a
        expect(all_abroad_ticket_orders).not_to be_empty, "未找到任何#{@origin}→#{@destination}的AbroadTicketOrder记录"
        @order = all_abroad_ticket_orders.first
      end
    
      return if @order.nil?
    
      # 断言2: 线路正确（核心实体验证）
      add_assertion "线路正确（#{@origin} → #{@destination}）", weight: 10 do
        expect(@order.abroad_ticket.origin).to eq(@origin),
          "出发地不正确。期望: #{@origin}, 实际: #{@order.abroad_ticket.origin}"
        expect(@order.abroad_ticket.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@order.abroad_ticket.destination}"
      end
    
      # 断言3: 日期正确
      add_assertion "出发日期正确（明天 #{@target_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@order.abroad_ticket.departure_date).to eq(@target_date),
          "出发日期不正确。期望: #{@target_date.strftime('%Y年%m月%d日')}（明天）, 实际: #{@order.abroad_ticket.departure_date.strftime('%Y年%m月%d日')}"
      end
    
      # 断言4: 乘客信息正确（验证来自 demo_user，不是硬编码）
      add_assertion "乘客信息正确（张三 13800138000）", weight: 10 do
        expect(@order.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.passenger_name}"
        expect(@order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
      end
    
      # 断言5: 选择了最便宜的班次（核心评分）
      add_assertion "选择了最便宜的班次", weight: 30 do
        # 重新查询该线路所有班次找出最低价
        route_trains = AbroadTicket.where(
          region: @region,
          ticket_type: 'train',
          origin: @origin,
          destination: @destination,
          departure_date: @target_date,
          data_version: 0
        )
      
        min_price = route_trains.minimum(:price)
        booked_price = @order.abroad_ticket.price
      
        # 允许0.01的浮点误差
        expect(booked_price).to be_within(0.01).of(min_price),
          "未选择最便宜的班次。该线路最低价: ¥#{min_price}, 实际预订: ¥#{booked_price}"
      end
    
      # 断言6: 订单金额准确
      add_assertion "订单金额准确", weight: 10 do
        expected_price = @order.abroad_ticket.price
      
        expect(@order.total_price).to be_within(0.01).of(expected_price),
          "订单金额不正确。预期: ¥#{expected_price}, 实际: ¥#{@order.total_price}"
      end
    
      # 断言7: 出行人数正确（1人）
      add_assertion "出行人数正确（#{@passenger_count}人）", weight: 10 do
        # AbroadTicketOrder模型是单个乘客，验证passenger_name存在
        expect(@order.passenger_name).to be_present,
          "未找到乘客信息"
      
        # 验证联系方式存在
        expect(@order.contact_phone).to be_present,
          "未找到乘客联系电话"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        region: @region,
        origin: @origin,
        destination: @destination,
        target_date: @target_date.to_s,
        passenger_count: @passenger_count,
        cheapest_price: @cheapest_price,
        total_trains: @total_trains
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @region = data['region']
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
      @passenger_count = data['passenger_count'] || 1
      @cheapest_price = data['cheapest_price']
      @total_trains = data['total_trains']
    end
  
    # 模拟 AI Agent 操作：搜索巴黎到阿姆斯特丹最便宜的火车票并预订
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找该线路的所有班次
      route_trains = AbroadTicket.where(
        region: @region,
        ticket_type: 'train',
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      )
    
      # 3. 找出最便宜的
      target_train = route_trains.order(:price).first
    
      # 4. 创建订单
      order = AbroadTicketOrder.create!(
        abroad_ticket_id: target_train.id,
        user_id: user.id,
        passenger_name: '张三',
        contact_phone: '13800138000',
        contact_email: 'demo@travel01.com',
        passenger_type: 'adult',
        seat_category: 'standard',
        total_price: target_train.price,
        status: 'pending',
        data_version: @data_version
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
end
