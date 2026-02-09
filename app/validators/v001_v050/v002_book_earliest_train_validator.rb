# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三预订明天上海到杭州最早的高铁（选二等座）
# 
# 任务描述:
#   Agent 需要在系统中搜索明天上海到杭州的所有高铁，
#   找到发车时间最早的车次并成功创建订单。
#   使用 demo_user 的出行人张三，优先选择二等座。
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 路线正确 (15分)
#   - 出发日期正确 (15分)
#   - 选择了最早的车次 (30分)
#   - 选择了二等座 (10分)
#   - 乘客信息正确 (5分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_earliest_train_sh_to_hz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V002BookEarliestTrainValidator < BaseValidator
    self.validator_id = 'v002_book_earliest_train_validator'
    self.task_id = '336024a2-f7ac-4ddc-a917-381c76c52a5c'
    self.title = '给张三预订明天上海到杭州最早的高铁（选二等座）'
    self.description = '在明天的车次中找到发车时间最早的高铁并为张三完成预订，选择二等座'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @origin = '上海'
      @destination = '杭州'
      @target_date = Date.current + 1.day  # 明天
    
      # 查找最早的车次（用于后续验证）
      # 注意：查询基线数据 (data_version=0)
      earliest_train = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
       .order(:departure_time)
       .first
    
      @earliest_departure_time = earliest_train&.departure_time
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三预订明天从#{@origin}到#{@destination}最早的高铁（选二等座）",
        passenger: '张三',
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
        seat_type: '二等座',
        requirement: '选择发车时间最早的车次',
        available_trains_count: Train.where(
          departure_city: @origin,
          arrival_city: @destination,
          data_version: 0
        ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date).count,
        earliest_time: @earliest_departure_time&.strftime('%H:%M')
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 查询订单并存储（第一条断言必须查询+过滤核心实体）
      add_assertion "创建了火车票订单", weight: 25 do
        # ✅ 查询时包含 data_version + 核心业务实体（路线）
        # ❌ 不包含待验证属性（日期、座位类型、乘客信息）
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { 
            departure_city: @origin, 
            arrival_city: @destination 
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, 
          "未找到任何#{@origin}到#{@destination}的火车票订单"
        
        @booking = all_bookings.first
      end
    
      return unless @booking # Guard clause
    
      # 断言2: 路线正确（核心实体验证）
      add_assertion "路线正确（#{@origin} → #{@destination}）", weight: 15 do
        expect(@booking.train.departure_city).to eq(@origin),
          "出发城市错误。期望: #{@origin}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@destination),
          "到达城市错误。期望: #{@destination}, 实际: #{@booking.train.arrival_city}"
      end
    
      # 断言3: 出发日期正确
      add_assertion "出发日期正确（明天）", weight: 15 do
        booking_date = @booking.train.departure_time.to_date
        expect(booking_date).to eq(@target_date),
          "出发日期错误。期望: #{@target_date}（明天）, 实际: #{booking_date}"
      end
    
      # 断言4: 选择了最早的车次（核心业务逻辑）
      add_assertion "选择了最早的车次", weight: 30 do
        # 查找该路线当天的所有车次
        all_trains = Train.where(
          departure_city: @origin,
          arrival_city: @destination,
          data_version: 0
        ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
      
        # 找出最早的发车时间
        earliest_time = all_trains.minimum(:departure_time)
      
        # 验证预订的车次是否为最早的
        expect(@booking.train.departure_time).to eq(earliest_time),
          "未选择最早车次。最早发车: #{earliest_time.strftime('%H:%M')} (#{all_trains.find_by(departure_time: earliest_time).train_number}), " \
          "实际选择: #{@booking.train.departure_time.strftime('%H:%M')} (#{@booking.train.train_number})"
      end
    
      # 断言5: 选择了二等座
      add_assertion "选择了二等座", weight: 10 do
        expect(@booking.seat_type).to eq('second_class'),
          "座位类型错误。期望: 二等座(second_class), 实际: #{@booking.seat_type_label}"
      end
      
      # 断言6: 乘客信息正确（数据规范验证）
      add_assertion "乘客信息正确（张三）", weight: 5 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        target_date: @target_date.to_s,
        origin: @origin,
        destination: @destination,
        earliest_departure_time: @earliest_departure_time&.iso8601
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @target_date = Date.parse(data['target_date'])
      @origin = data['origin']
      @destination = data['destination']
      @earliest_departure_time = Time.zone.parse(data['earliest_departure_time']) if data['earliest_departure_time']
    end
  
    # 模拟 AI Agent 操作：预订上海到杭州最早的高铁
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客（数据包中已创建）
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      # 3. 查找目标车次（最早的）
      target_train = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
       .order(:departure_time)
       .first
    
      # 4. 查找二等座座位
      seat = target_train.train_seats.find_by(seat_type: 'second_class')
    
      # 5. 创建订单（固定参数）
      booking = TrainBooking.create!(
        train_id: target_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        accept_terms: true,
        total_price: seat.price,
        status: 'pending'
      )
    
      # 返回操作信息
      {
        action: 'create_train_booking',
        booking_id: booking.id,
        train_number: target_train.train_number,
        departure_time: target_train.departure_time.strftime('%H:%M'),
        seat_price: seat.price,
        passenger_name: passenger.name,
        user_email: user.email
      }
    end
    end
end
