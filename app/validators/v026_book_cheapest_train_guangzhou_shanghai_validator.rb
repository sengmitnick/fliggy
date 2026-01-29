# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例26: 预订明天广州到上海最便宜的高铁（二等座）
# 
# 任务描述:
#   Agent 需要在系统中搜索明天广州到上海的所有高铁，
#   找到二等座价格最低的车次并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索广州到上海的路线
#   2. 需要选择"明天"日期
#   3. 需要对比二等座价格，选择最便宜的
#   ❌ 价格优先，座位固定为二等座
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 路线正确（广州→上海） (20分)
#   - 出发日期正确（明天） (20分)
#   - 选择了最便宜的车次 (30分)
#   - 座位类型正确（二等座） (10分)
#
class V026BookCheapestTrainGuangzhouShanghaiValidator < BaseValidator
  self.validator_id = 'v026_book_cheapest_train_guangzhou_shanghai_validator'
  self.task_id = '59234a60-b49c-4058-9813-7383c55efeb4'
  self.title = '预订明天广州到上海最便宜的高铁（二等座）'
  self.description = '在明天的车次中找到二等座价格最低的高铁并完成预订'
  self.timeout_seconds = 240
  
  def prepare
    @origin = '广州'
    @destination = '上海'
    @target_date = Date.current + 1.day
    @seat_type = 'second_class'
    
    available_trains = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
    
    train_prices = available_trains.map do |train|
      seat = train.train_seats.find_by(seat_type: @seat_type)
      { train_id: train.id, price: seat&.price || Float::INFINITY }
    end
    
    @lowest_price = train_prices.map { |tp| tp[:price] }.min
    
    {
      task: "请预订一张明天从#{@origin}到#{@destination}最便宜的高铁票（二等座）",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "明天（#{@target_date.strftime('%Y年%m月%d日')}）",
      seat_requirement: "二等座",
      hint: "系统中有多个车次可选，请选择二等座价格最低的",
      lowest_price: @lowest_price
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @booking = TrainBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何火车票订单记录"
    end
    
    return unless @booking
    
    add_assertion "出发城市正确", weight: 10 do
      expect(@booking.train.departure_city).to eq(@origin)
    end
    
    add_assertion "到达城市正确", weight: 10 do
      expect(@booking.train.arrival_city).to eq(@destination)
    end
    
    add_assertion "出发日期正确", weight: 20 do
      booking_date = @booking.train.departure_time.to_date
      expect(booking_date).to eq(@target_date)
    end
    
    add_assertion "选择了最便宜的车次", weight: 30 do
      all_trains = Train.where(
        departure_city: @origin,
        arrival_city: @destination
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
      
      train_prices = all_trains.map do |train|
        seat = train.train_seats.find_by(seat_type: @seat_type)
        seat&.price || Float::INFINITY
      end
      
      lowest_price = train_prices.min
      booked_seat = @booking.train.train_seats.find_by(seat_type: @seat_type)
      
      expect(booked_seat.price).to eq(lowest_price),
        "未选择最便宜车次。最低价: #{lowest_price}元, 实际选择: #{booked_seat.price}元"
    end
    
    add_assertion "座位类型正确（二等座）", weight: 10 do
      expect(@booking.seat_type).to eq(@seat_type)
    end
  end
  
  private
  
  def execution_state_data
    { origin: @origin, destination: @destination, target_date: @target_date.to_s, seat_type: @seat_type }
  end
  
  def restore_from_state(data)
    @origin = data['origin']
    @destination = data['destination']
    @target_date = Date.parse(data['target_date'])
    @seat_type = data['seat_type']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    available_trains = Train.where(
      departure_city: @origin,
      arrival_city: @destination,
      data_version: 0
    ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @target_date)
    
    cheapest_train = available_trains.min_by do |train|
      seat = train.train_seats.find_by(seat_type: @seat_type)
      seat&.price || Float::INFINITY
    end
    
    raise "No train found for #{@origin} to #{@destination} on #{@target_date}" if cheapest_train.nil?
    
    seat = cheapest_train.train_seats.find_by(seat_type: @seat_type)
    raise "No #{@seat_type} seat available on train #{cheapest_train.train_number}" if seat.nil?
    
    TrainBooking.create!(
      train_id: cheapest_train.id,
      user_id: user.id,
      passenger_name: passenger.name,
      passenger_id_number: passenger.id_number,
      contact_phone: passenger.phone,
      seat_type: @seat_type,
      accept_terms: true,
      total_price: seat.price,
      status: 'pending'
    )
    
    { action: 'create_train_booking', train_number: cheapest_train.train_number }
  end
end