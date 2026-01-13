# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例1: 预订深圳到北京的低价机票
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳到北京的航班，
#   找到价格最低的航班并成功创建订单
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 航线正确 (20分)
#   - 出发日期正确 (20分)
#   - 选择了最低价航班 (40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_flight_sz_to_bj/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class BookFlightValidator < BaseValidator
  self.validator_id = 'book_flight_sz_to_bj'
  self.title = '预订深圳到北京的低价机票'
  self.description = '在今天的航班中找到价格最低的机票并完成预订'
  self.data_pack_version = 'flights_v1'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    # 设置任务参数
    @target_date = Date.parse('2024-12-20')
    @origin = '深圳'
    @destination = '北京'
    
    # 计算最低价（用于后续验证）
    @lowest_price = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date
    ).minimum(:price)
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一张#{@origin}到#{@destination}的低价机票",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      hint: "系统中有多个航班可选，请选择价格最低的航班",
      available_flights_count: Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date
      ).count,
      lowest_price: @lowest_price
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何订单记录"
    end
    
    return unless @booking # 如果没有订单，后续断言无法继续
    
    # 断言2: 航线正确
    add_assertion "出发城市正确", weight: 10 do
      expect(@booking.flight.departure_city).to eq(@origin)
    end
    
    add_assertion "目的城市正确", weight: 10 do
      expect(@booking.flight.destination_city).to eq(@destination)
    end
    
    # 断言3: 出发日期正确
    add_assertion "出发日期正确", weight: 20 do
      expect(@booking.flight.flight_date).to eq(@target_date)
    end
    
    # 断言4: 选择了最低价航班（核心评分项）
    add_assertion "选择了最低价航班", weight: 40 do
      # 查找该航线的所有航班
      all_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date
      )
      
      # 计算最低价
      lowest_price = all_flights.minimum(:price)
      
      # 验证预订的航班是否为最低价
      expect(@booking.flight.price).to eq(lowest_price),
        "未选择最低价航班。最低价: #{lowest_price}, 实际选择: #{@booking.flight.price}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      target_date: @target_date.to_s,
      origin: @origin,
      destination: @destination,
      lowest_price: @lowest_price
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @target_date = Date.parse(data['target_date'])
    @origin = data['origin']
    @destination = data['destination']
    @lowest_price = data['lowest_price']
  end
end
