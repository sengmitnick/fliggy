# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 搜索明天广州到深圳的大巴票，找到上午（12点前）出发的班次并预订
# 
# 任务描述:
#   Agent 需要在系统中搜索明天广州到深圳的大巴票，
#   找到上午（12点前）出发的班次并使用 demo_user 的 passenger 数据创建订单
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（广州→深圳） (20分)
#   - 出发日期正确（明天） (15分)
#   - 时间段正确（上午） (30分)
#   - 乘客信息来自 demo_user (15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_morning_bus_gz_to_sz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V006BookMorningBusValidator < BaseValidator
    self.validator_id = 'v006_book_morning_bus_validator'
    self.task_id = '2d9b3ddf-7810-4c6e-9dc9-06bb34952efb'
    self.title = '给张三预订明天上午广州到深圳的大巴票'
    self.description = '搜索明天广州到深圳的大巴票，找到上午（12点前）出发的班次并预订'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @origin = '广州'
      @destination = '深圳'
      @target_date = Date.current + 1.day  # 明天
      @morning_cutoff = '12:00'
    
      # 查找符合条件的班次（用于后续验证）
      # 注意：查询基线数据 (data_version=0)
      morning_buses = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('departure_time < ?', @morning_cutoff)
    
      @morning_count = morning_buses.count
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三预订明天上午广州到深圳的大巴票",
        origin: @origin,
        destination: @destination,
        date: @target_date.to_s,
        date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
        time_requirement: "上午（12:00之前出发）",
        passenger: "张三",
        hint: "系统中有多个班次可选，请选择上午出发的",
        morning_buses_count: @morning_count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "创建了大巴票订单", weight: 20 do
        all_bus_ticket_orders = BusTicketOrder
          .includes(:bus_ticket)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bus_ticket_orders).not_to be_empty, "未找到任何大巴票订单记录"
        @order = all_bus_ticket_orders.first
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 路线正确（广州→深圳）
      add_assertion "路线正确（广州→深圳）", weight: 20 do
        expect(@order.bus_ticket.origin).to eq(@origin),
          "出发城市错误。期望: #{@origin}, 实际: #{@order.bus_ticket.origin}"
        expect(@order.bus_ticket.destination).to eq(@destination),
          "目的城市错误。期望: #{@destination}, 实际: #{@order.bus_ticket.destination}"
      end
    
      # 断言3: 出发日期正确（明天）
      add_assertion "出发日期正确（明天 #{@target_date.strftime('%m月%d日')}）", weight: 15 do
        expect(@order.bus_ticket.departure_date).to eq(@target_date),
          "出发日期错误。期望: #{@target_date}（明天）, 实际: #{@order.bus_ticket.departure_date}"
      end
    
      # 断言4: 时间段正确（上午）（核心评分项）
      add_assertion "出发时间在上午（12:00之前）", weight: 30 do
        departure_time = @order.bus_ticket.departure_time
      
        expect(departure_time).to be < @morning_cutoff,
          "出发时间不在上午。要求: 12:00之前, 实际: #{departure_time}"
      end
    
      # 断言5: 乘客信息来自 demo_user（数据规范验证）
      add_assertion "乘客信息来自 demo_user（张三 110101199001011234）", weight: 15 do
        passengers = @order.passengers.to_a
        expect(passengers).not_to be_empty, "订单缺少乘客信息"
        
        passenger = passengers.first
        expect(passenger.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{passenger.passenger_name}"
        expect(passenger.passenger_id_number).to eq('110101199001011234'),
          "乘客证件号错误。期望: 110101199001011234（demo_user数据）, 实际: #{passenger.passenger_id_number}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        origin: @origin,
        destination: @destination,
        target_date: @target_date.to_s,
        morning_cutoff: @morning_cutoff,
        morning_count: @morning_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @origin = data['origin']
      @destination = data['destination']
      @target_date = Date.parse(data['target_date'])
      @morning_cutoff = data['morning_cutoff']
      @morning_count = data['morning_count']
    end
  
    # 模拟 AI Agent 操作：给张三预订明天上午广州到深圳的大巴票
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客信息（使用 demo_user 的 passengers 数据）
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 3. 查找符合条件的班次（上午）
      morning_buses = BusTicket.where(
        origin: @origin,
        destination: @destination,
        departure_date: @target_date,
        data_version: 0
      ).where('departure_time < ?', @morning_cutoff)
    
      raise "未找到符合条件的上午班次" if morning_buses.empty?
    
      # 随机选择一个
      target_bus = morning_buses.sample
    
      # 4. 创建订单（会话隔离数据）
      order = BusTicketOrder.create!(
        bus_ticket_id: target_bus.id,
        user_id: user.id,
        passenger_count: 1,
        total_price: target_bus.price,
        status: 'pending',
        data_version: @data_version  # 会话隔离
      )
    
      # 5. 创建乘客信息（使用 demo_user 的 passenger 数据）
      order.passengers.create!(
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        data_version: @data_version  # 会话隔离
      )
    
      # 返回操作信息
      {
        action: 'create_bus_ticket_order',
        order_id: order.id,
        passenger_name: passenger.name,
        departure_time: target_bus.departure_time,
        arrival_time: target_bus.arrival_time,
        price: target_bus.price,
        user_email: user.email
      }
    end
    end
end
