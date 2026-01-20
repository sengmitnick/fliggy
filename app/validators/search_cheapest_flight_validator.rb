# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例2: 搜索上海到深圳的最便宜航班
# 
# 任务描述:
#   Agent 需要搜索上海到深圳的所有航班，
#   找出价格最便宜的航班（考虑折扣价），
#   并创建订单
# 
# 评分标准:
#   - 搜索到了所有可用航班 (20分)
#   - 正确识别最便宜的航班 (30分)
#   - 成功创建订单 (20分)
#   - 订单金额准确 (30分)
# 
# 难点:
#   - 需要考虑 discount_price（折扣价）
#   - 最终价格 = price - discount_price
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_cheapest_sh_to_sz/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchCheapestFlightValidator < BaseValidator
  self.validator_id = 'search_cheapest_sh_to_sz'
  self.title = '搜索并预订上海到深圳的最便宜航班'
  self.description = '搜索后天上海到深圳的所有航班，找出价格最便宜的（考虑折扣后）并完成预订'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    @origin = '上海'
    @destination = '深圳'
    @target_date = Date.current + 2.days  # 后天
    
    # 查找所有航班（注意：查询基线数据）
    flights = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      data_version: 0
    )
    
    # 计算每个航班的最终价格（考虑折扣）
    @flight_prices = flights.map do |f|
      {
        id: f.id,
        flight_number: f.flight_number,
        original_price: f.price,
        discount: f.discount_price,
        final_price: f.price - f.discount_price
      }
    end
    
    # 找出最便宜的航班
    @cheapest_flight = @flight_prices.min_by { |f| f[:final_price] }
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索后天从#{@origin}到#{@destination}的所有航班，找出最便宜的并预订",
      departure_city: @origin,
      destination_city: @destination,
      date: @target_date.to_s,
      date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
      hint: "注意：有些航班有折扣，需要计算最终价格 = 原价 - 折扣",
      total_flights: flights.count,
      price_range: {
        min: @cheapest_flight[:final_price],
        max: @flight_prices.max_by { |f| f[:final_price] }[:final_price]
      }
    }
  end
  
  # 验证阶段：检查是否找到并预订了最便宜的航班
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @booking = Booking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何订单记录"
    end
    
    return unless @booking
    
    # 断言2: 航线正确
    add_assertion "航线正确（上海→深圳）", weight: 10 do
      expect(@booking.flight.departure_city).to eq(@origin)
      expect(@booking.flight.destination_city).to eq(@destination)
    end
    
    # 断言3: 日期正确
    add_assertion "出发日期正确", weight: 10 do
      expect(@booking.flight.flight_date).to eq(@target_date)
    end
    
    # 断言4: 正确识别最便宜的航班（核心评分）
    add_assertion "选择了最便宜的航班（考虑折扣）", weight: 30 do
      # 重新计算所有航班价格（注意：查询基线数据）
      all_flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      )
      
      # 找出最低最终价格
      cheapest = all_flights.min_by { |f| f.price - f.discount_price }
      cheapest_final_price = cheapest.price - cheapest.discount_price
      
      # 实际预订的航班价格
      booked_final_price = @booking.flight.price - @booking.flight.discount_price
      
      expect(booked_final_price).to eq(cheapest_final_price),
        "未选择最便宜航班。最低价: ¥#{cheapest_final_price} (#{cheapest.flight_number}), " \
        "实际选择: ¥#{booked_final_price} (#{@booking.flight.flight_number})"
    end
    
    # 断言5: 订单金额准确
    add_assertion "订单总价准确", weight: 30 do
      expected_price = @booking.flight.price - @booking.flight.discount_price
      
      # 允许有保险费用
      if @booking.insurance_price.present? && @booking.insurance_price > 0
        expected_price += @booking.insurance_price
      end
      
      expect(@booking.total_price).to be_within(1).of(expected_price),
        "订单金额不正确。预期: ¥#{expected_price}, 实际: ¥#{@booking.total_price}"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      target_date: @target_date.to_s,
      origin: @origin,
      destination: @destination,
      flight_prices: @flight_prices,
      cheapest_flight: @cheapest_flight
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @target_date = Date.parse(data['target_date'])
    @origin = data['origin']
    @destination = data['destination']
    @flight_prices = data['flight_prices']
    @cheapest_flight = data['cheapest_flight']
  end
  
  # 模拟 AI Agent 操作：搜索上海到深圳最便宜航班并预订
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找乘客
    passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
    # 3. 查找最便宜航班（考虑折扣）
    # 数据包固定，这里的查询结果是确定的
    target_flight = Flight.where(
      departure_city: @origin,
      destination_city: @destination,
      flight_date: @target_date,
      data_version: 0
    ).min_by { |f| f.price - f.discount_price }
    
    # 4. 创建订单（固定参数）
    final_price = target_flight.price - target_flight.discount_price
    booking = Booking.create!(
      flight_id: target_flight.id,
      user_id: user.id,
      passenger_name: passenger.name,
      passenger_id_number: passenger.id_number,
      contact_phone: passenger.phone,
      total_price: final_price,
      status: 'pending',
      accept_terms: true
    )
    
    # 返回操作信息
    {
      action: 'create_booking',
      booking_id: booking.id,
      flight_number: target_flight.flight_number,
      original_price: target_flight.price,
      discount: target_flight.discount_price,
      final_price: final_price,
      passenger_name: passenger.name,
      user_email: user.email
    }
  end
end
