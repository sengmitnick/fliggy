# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 搜索后天北京到天津最便宜的车票（1人）
# 
# 任务描述:
#   Agent 需要搜索后天北京到天津的所有车次，
#   找出价格最便宜的车票（对比不同座位类型），
#   并创建订单（1人出行）
# 
# 评分标准:
#   - 搜索到了所有可用车次 (15分)
#   - 正确识别最便宜的车票 (25分)
#   - 成功创建订单 (20分)
#   - 订单金额准确 (20分)
#   - 出行人数正确（1人） (20分)
# 
# 难点:
#   - 需要对比不同车次和不同座位类型
#   - 商务座可能是二等座的3倍价格
#   - 需要在所有组合中找到最便宜的
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_cheapest_train_bj_to_tj/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V011SearchCheapestTrainSeatValidator < BaseValidator
    self.validator_id = 'v011_search_cheapest_train_seat_validator'
    self.task_id = 'd75371f7-bbc5-489d-a7e6-c1a4a8222c82'
    self.title = '给张三订后天去天津的火车票（选最便宜的）'
    self.description = '给张三预订后天从北京到天津的火车票，找出最便宜的车票（对比不同座位类型）并完成预订'
    self.timeout_seconds = 300
  
    # 准备阶段：插入测试数据
    def prepare
      # 数据已经通过 load_data_pack 自动加载
      @origin = '北京'
      @destination = '天津'
      @target_date = Date.current + 2.days  # 后天
      @passenger_count = 1  # 出行人数
    
      # 查找所有车次（注意：查询基线数据）
      trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
    
      # 计算每趟车每种座位类型的价格
      @seat_prices = []
      trains.each do |train|
        train.train_seats.where(data_version: 0).each do |seat|
          next if seat.available_count <= 0 # 跳过无票的座位
        
          @seat_prices << {
            train_id: train.id,
            train_number: train.train_number,
            seat_type: seat.seat_type,
            price: seat.price,
            available: seat.available_count
          }
        end
      end
    
      # 找出最便宜的组合
      @cheapest_option = @seat_prices.min_by { |s| s[:price] }
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三订后天去天津的火车票（选最便宜的）",
        task_detail: "请搜索后天从#{@origin}到#{@destination}的所有车次，找出最便宜的车票并预订（#{@passenger_count}人出行）",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        passenger_count: @passenger_count,
        hint: "注意：不同车次和不同座位类型（二等座/一等座/商务座）价格差异很大，需要全面对比",
        total_trains: trains.count,
        price_range: {
          min: @cheapest_option[:price],
          max: @seat_prices.max_by { |s| s[:price] }[:price]
        },
        seat_types_available: @seat_prices.map { |s| s[:seat_type] }.uniq
      }
    end
  
    # 验证阶段：检查是否找到并预订了最便宜的车票
    def verify
      # 断言1: 必须有订单创建（查询过滤核心实体：路线）
      add_assertion "创建了火车票订单", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .where(
            trains: {
              departure_city: @origin,
              arrival_city: @destination,
              data_version: 0
            },
            data_version: @data_version
          )
          .order(created_at: :desc)
          .to_a
        expect(all_train_bookings).not_to be_empty, "未找到任何#{@origin}→#{@destination}的TrainBooking记录"
        @booking = all_train_bookings.first
      end
    
      return if @booking.nil?
    
      # 断言2: 路线正确（核心实体验证）
      add_assertion "路线正确（北京→天津）", weight: 10 do
        expect(@booking.train.departure_city).to eq(@origin),
          "出发城市错误。期望: #{@origin}, 实际: #{@booking.train.departure_city}"
        expect(@booking.train.arrival_city).to eq(@destination),
          "到达城市错误。期望: #{@destination}, 实际: #{@booking.train.arrival_city}"
      end
    
      # 断言3: 日期正确
      add_assertion "出发日期正确（后天 #{@target_date.strftime('%m月%d日')}）", weight: 10 do
        booking_date = @booking.train.departure_time.to_date
        expect(booking_date).to eq(@target_date),
          "出发日期不正确。期望: #{@target_date.strftime('%Y年%m月%d日')}（后天）, 实际: #{booking_date.strftime('%Y年%m月%d日')}"
      end
    
      # 断言4: 乘客信息正确（验证来自 demo_user，不是硬编码）
      add_assertion "乘客信息正确（张三 13800138000）", weight: 10 do
        expect(@booking.passenger_name).to eq('张三'),
          "乘客姓名错误。期望: 张三（demo_user数据）, 实际: #{@booking.passenger_name}"
        expect(@booking.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@booking.contact_phone}"
      end
    
      # 断言5: 正确识别最便宜的车票（核心评分）
      add_assertion "选择了最便宜的车票（对比所有座位类型）", weight: 25 do
        # 重新计算所有车次所有座位类型的价格
        all_trains = Train.where(
          departure_city: @origin,
          arrival_city: @destination,
          data_version: 0
        ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
      
        # 找出最低价格
        cheapest_price = Float::INFINITY
        cheapest_info = nil
      
        all_trains.each do |train|
          train.train_seats.where(data_version: 0).each do |seat|
            next if seat.available_count <= 0
          
            if seat.price < cheapest_price
              cheapest_price = seat.price
              cheapest_info = {
                train_number: train.train_number,
                seat_type: seat.seat_type,
                price: seat.price
              }
            end
          end
        end
      
        # 获取实际预订的座位价格
        booked_seat = @booking.train.train_seats.find_by(seat_type: @booking.seat_type)
        booked_price = booked_seat&.price || @booking.total_price
      
        expect(booked_price).to be_within(0.5).of(cheapest_price),
          "未选择最便宜车票。最低价: ¥#{cheapest_price} (#{cheapest_info[:train_number]} #{cheapest_info[:seat_type]}), " \
          "实际选择: ¥#{booked_price} (#{@booking.train.train_number} #{@booking.seat_type})"
      end
    
      # 断言6: 订单金额准确
      add_assertion "订单总价准确", weight: 15 do
        # 获取座位价格
        seat = @booking.train.train_seats.find_by(seat_type: @booking.seat_type)
        expected_price = seat.price
      
        expect(@booking.total_price).to be_within(1).of(expected_price),
          "订单金额不正确。预期: ¥#{expected_price}, 实际: ¥#{@booking.total_price}"
      end
    
      # 断言7: 出行人数正确（1人）
      add_assertion "出行人数正确（#{@passenger_count}人）", weight: 10 do
        # TrainBooking模型是单个乘客，验证passenger_name存在
        expect(@booking.passenger_name).to be_present,
          "未找到乘客信息"
      
        # 验证身份证号码存在
        expect(@booking.passenger_id_number).to be_present,
          "未找到乘客身份证信息"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        target_date: @target_date.to_s,
        origin: @origin,
        destination: @destination,
        passenger_count: @passenger_count,
        seat_prices: @seat_prices,
        cheapest_option: @cheapest_option
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @target_date = Date.parse(data['target_date'])
      @origin = data['origin']
      @destination = data['destination']
      @passenger_count = data['passenger_count'] || 1
      @seat_prices = data['seat_prices']
      @cheapest_option = data['cheapest_option']
    end
  
    # 模拟 AI Agent 操作：搜索北京到天津最便宜车票并预订
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客（使用 demo_user 关联查询）
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 3. 查找最便宜的车票（遍历所有车次和座位类型）
      all_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
    
      cheapest_price = Float::INFINITY
      target_train = nil
      target_seat = nil
    
      all_trains.each do |train|
        train.train_seats.where(data_version: 0).each do |seat|
          next if seat.available_count <= 0
        
          if seat.price < cheapest_price
            cheapest_price = seat.price
            target_train = train
            target_seat = seat
          end
        end
      end
    
      # 4. 创建订单
      booking = TrainBooking.create!(
        train_id: target_train.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: target_seat.seat_type,
        accept_terms: true,
        total_price: target_seat.price,
        status: 'pending',
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_train_booking',
        booking_id: booking.id,
        train_number: target_train.train_number,
        seat_type: target_seat.seat_type,
        seat_price: target_seat.price,
        passenger_name: passenger.name,
        user_email: user.email
      }
    end
    end
end
