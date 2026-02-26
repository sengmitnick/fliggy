# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 需要在系统中搜索深圳到北京后天的航班，找到价格最低的航班并为张三成功创建订单。
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳到北京后天的航班，
#   找到价格最低的航班并为张三成功创建订单。
#   
#   具体要求:
#   - 受益人: 张三（demo_user 的 passenger）
#   - 出发城市: 深圳
#   - 目的城市: 北京
#   - 出发日期: 后天（当前日期 + 2天）
#   - 价格要求: 必须选择该航线当天的最低价航班
#   
#   测试场景:
#   系统中会有多个深圳到北京的航班，价格各不相同。
#   Agent 需要正确筛选目标日期的航班，对比价格，选择最便宜的选项，
#   并使用 demo_user 的出行人数据（张三）填写订单信息。
# 
# 评分标准:
#   - 订单已创建 (20分) - 系统中存在新创建的订单记录
#   - 出发城市正确 (10分) - 订单中的航班出发城市为深圳
#   - 目的城市正确 (10分) - 订单中的航班目的城市为北京
#   - 出发日期正确 (15分) - 订单中的航班日期为后天（+2天）
#   - 乘客信息正确 (10分) - 乘客姓名和身份证号来自 demo_user 的 passengers（张三）
#   - 选择了最低价航班 (35分) - 所选航班价格等于该航线当天的最低价
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_flight_sz_to_bj/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V003BookFlightValidator < BaseValidator
    self.validator_id = 'v003_book_flight_validator'
    self.task_id = '5fb8453d-648a-4944-bb52-7e0e7eb4f58c'
    self.title = '给张三订后天从深圳到北京的最便宜机票'
    self.description = '需要在系统中搜索深圳到北京后天的航班，找到价格最低的航班并为张三成功创建订单。'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @origin = '深圳'
      @destination = '北京'
      @target_date = Date.current + 2.days  # 后天
    
      # 计算最低价（用于后续验证）
      # 注意：查询基线数据 (data_version=0)
      @lowest_price = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      ).minimum(:price)
    
      # 计算可用航班的价格范围
      available_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      )
      max_price = available_flights.maximum(:price)
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三订后天从#{@origin}到#{@destination}的最便宜机票",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        passenger_name: "张三",
        requirement: "必须选择该航线当天的最低价航班，乘客信息使用张三（demo_user 的出行人）",
        hint: "系统中有多个航班可选，价格从 #{@lowest_price} 元到 #{max_price} 元不等，请仔细对比后选择最便宜的航班",
        available_flights_count: available_flights.count,
        price_range: {
          lowest: @lowest_price,
          highest: max_price
        },
        scoring_note: "选择最低价航班占评分权重35%，乘客信息正确占10%，请务必使用 demo_user 的出行人数据"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        all_bookings = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_bookings).not_to be_empty, "未找到任何订单记录"
        @booking = all_bookings.first
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
      add_assertion "出发日期正确（后天 #{@target_date}）", weight: 15 do
        expect(@booking.flight.flight_date).to eq(@target_date),
          "出发日期错误。期望: #{@target_date}（后天）, 实际: #{@booking.flight.flight_date}"
      end
    
      # 断言4: 乘客信息正确（来自 demo_user 数据）
      add_assertion "乘客信息正确（张三 110101199001011234）", weight: 10 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user 出行人）, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq('110101199001011234'),
          "乘客身份证号错误。期望: 110101199001011234（张三的身份证号）, 实际: #{@booking.passenger_id_number}"
      end
    
      # 断言5: 选择了最低价航班（核心评分项）
      add_assertion "选择了最低价航班", weight: 35 do
        # 查找该航线的所有航班
        all_flights = Flight.where(
          departure_city: @origin,
          destination_city: @destination,
          flight_date: @target_date,
          data_version: 0
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
  
    # 模拟 AI Agent 操作：预订深圳到北京的最低价航班
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客（数据包中已创建）
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      # 3. 查找目标航班（数据包固定，直接查最低价）
      target_flight = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      ).order(:price).first
    
      # 4. 创建订单（固定参数）
      booking = Booking.create!(
        flight_id: target_flight.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: target_flight.price,
        status: 'pending',
        accept_terms: true
      )
    
      # 返回操作信息
      {
        action: 'create_booking',
        booking_id: booking.id,
        flight_number: target_flight.flight_number,
        flight_price: target_flight.price,
        passenger_name: passenger.name,
        user_email: user.email
      }
    end
    end
end
