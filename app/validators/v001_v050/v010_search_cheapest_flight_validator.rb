# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 搜索上海到深圳的最便宜航班套餐（后天1人）
# 
# 任务描述:
#   Agent 需要搜索后天上海到深圳的所有航班套餐（FlightOffer），
#   找出最终成本最低的套餐（考虑返现），
#   并创建订单（1人出行）
# 
# 评分标准:
#   - 搜索到了所有可用航班套餐 (15分)
#   - 正确识别最优惠的套餐（考虑返现） (25分)
#   - 成功创建订单 (20分)
#   - 订单支付金额准确 (20分)
#   - 出行日期正确（后天） (10分)
#   - 出行人数正确（1人） (10分)
# 
# 难点:
#   - 需要考虑 cashback_amount（支付后返现）
#   - 最终成本 = offer.price - offer.cashback_amount
#   - 订单支付金额 = offer.price（全额支付，不扣除返现）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_cheapest_sh_to_sz/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V010SearchCheapestFlightValidator < BaseValidator
    self.validator_id = 'v010_search_cheapest_flight_validator'
    self.task_id = '3d62bb93-09a6-42c5-8a8e-1e6c999eabb2'
    self.title = '搜索上海到深圳的最便宜航班套餐（后天1人）'
    self.description = '搜索后天上海到深圳的所有航班套餐，找出最终成本最低的并完成预订（考虑返现，1人出行）'
    self.timeout_seconds = 300
  
    # 准备阶段：插入测试数据
    def prepare
      # 数据已经通过 load_data_pack 自动加载
      @origin = '上海'
      @destination = '深圳'
      @target_date = Date.current + 2.days  # 后天
      @passenger_count = 1  # 出行人数
    
      # 查找所有航班及其套餐（注意：查询基线数据）
      flights = Flight.where(
        departure_city: @origin,
        destination_city: @destination,
        flight_date: @target_date,
        data_version: 0
      ).includes(:flight_offers)
    
      # 收集所有套餐的价格信息
      @offer_prices = []
      flights.each do |flight|
        flight.flight_offers.each do |offer|
          @offer_prices << {
            offer_id: offer.id,
            flight_id: flight.id,
            flight_number: flight.flight_number,
            provider_name: offer.provider_name,
            price: offer.price,
            cashback_amount: offer.cashback_amount,
            final_cost: offer.price - offer.cashback_amount
          }
        end
      end
    
      # 找出最终成本最低的套餐
      @cheapest_offer = @offer_prices.min_by { |o| o[:final_cost] }
    
      # 返回给 Agent 的任务信息
      {
        task: "请搜索后天从#{@origin}到#{@destination}的所有航班套餐，找出最终成本最低的并预订（#{@passenger_count}人出行）",
        departure_city: @origin,
        destination_city: @destination,
        date: @target_date.to_s,
        date_description: "后天（#{@target_date.strftime('%Y年%m月%d日')}）",
        passenger_count: @passenger_count,
        hint: "注意：有些套餐有返现，需要计算最终成本 = 支付价格 - 返现金额",
        total_flights: flights.count,
        total_offers: @offer_prices.count,
        price_range: {
          min_cost: @cheapest_offer[:final_cost],
          max_cost: @offer_prices.max_by { |o| o[:final_cost] }[:final_cost]
        }
      }
    end
  
    # 验证阶段：检查是否找到并预订了最优惠的套餐
    def verify
      # 断言1: 必须有订单创建
      add_assertion "订单已创建", weight: 20 do
        @booking = Booking.where(data_version: @data_version).order(created_at: :desc).first
        expect(@booking).not_to be_nil, "未找到任何订单记录"
      end
    
      return unless @booking
    
      # 断言2: 航线正确
      add_assertion "航线正确（上海→深圳）", weight: 10 do
        expect(@booking.flight.departure_city).to eq(@origin)
        expect(@booking.flight.destination_city).to eq(@destination)
      end
    
      # 断言3: 日期正确
      add_assertion "出行日期正确（后天）", weight: 10 do
        expect(@booking.flight.flight_date).to eq(@target_date),
          "出行日期不正确。预期: #{@target_date.strftime('%Y年%m月%d日')}, 实际: #{@booking.flight.flight_date.strftime('%Y年%m月%d日')}"
      end
    
      # 断言4: 正确识别最优惠的套餐（考虑返现后的最终成本）（核心评分）
      add_assertion "选择了最优惠的套餐（考虑返现后成本最低）", weight: 30 do
        # 重新计算所有套餐的最终成本（注意：查询基线数据）
        all_offers = FlightOffer.joins(:flight).where(
          flights: {
            departure_city: @origin,
            destination_city: @destination,
            flight_date: @target_date,
            data_version: 0
          },
          data_version: 0
        )
      
        # 找出最终成本最低的套餐
        cheapest_offer = all_offers.min_by { |o| o.price - o.cashback_amount }
        cheapest_final_cost = cheapest_offer.price - cheapest_offer.cashback_amount
      
        # 实际预订的套餐（通过 flight_id 匹配，因为 Booking 不直接关联 FlightOffer）
        booked_flight_offers = @booking.flight.flight_offers.where(data_version: 0)
        booked_offer = booked_flight_offers.find { |o| o.price == @booking.total_price } || booked_flight_offers.min_by { |o| o.price - o.cashback_amount }
        booked_final_cost = booked_offer ? (booked_offer.price - booked_offer.cashback_amount) : @booking.total_price
      
        expect(booked_final_cost).to eq(cheapest_final_cost),
          "未选择最优惠套餐。最低成本: ¥#{cheapest_final_cost} (#{cheapest_offer.provider_name}, 航班#{cheapest_offer.flight.flight_number}), " \
          "实际选择成本: ¥#{booked_final_cost} (航班#{@booking.flight.flight_number})"
      end
    
      # 断言5: 订单支付金额准确（应该是 offer.price，不扣除返现）
      add_assertion "订单支付金额准确（全额支付，返现后续到账）", weight: 20 do
        # 根据预订的航班，找到对应的套餐
        booked_flight_offers = @booking.flight.flight_offers.where(data_version: 0)
        
        # 尝试通过价格匹配找到实际选择的套餐
        matched_offer = booked_flight_offers.find { |o| o.price == @booking.total_price }
        
        if matched_offer
          # 如果找到匹配的套餐，验证订单金额等于套餐价格
          expected_price = matched_offer.price
          expect(@booking.total_price).to be_within(1).of(expected_price),
            "订单支付金额不正确。预期: ¥#{expected_price} (#{matched_offer.provider_name}), 实际: ¥#{@booking.total_price}"
        else
          # 如果没找到匹配的套餐，验证订单金额在合理范围内
          min_offer_price = booked_flight_offers.minimum(:price)
          max_offer_price = booked_flight_offers.maximum(:price)
          expect(@booking.total_price).to be >= min_offer_price,
            "订单金额低于最低套餐价格。最低: ¥#{min_offer_price}, 实际: ¥#{@booking.total_price}"
          expect(@booking.total_price).to be <= max_offer_price,
            "订单金额高于最高套餐价格。最高: ¥#{max_offer_price}, 实际: ¥#{@booking.total_price}"
        end
      end
    
      # 断言6: 出行人数正确（1人）
      add_assertion "出行人数正确（#{@passenger_count}人）", weight: 10 do
        # Booking模型是单个乘客，验证passenger_name存在
        expect(@booking.passenger_name).to be_present,
          "未找到乘客信息"
      
        # 验证只有一个乘客（不是往返票或多程票）
        expect(@booking.trip_type).to eq('one_way').or(be_nil),
          "订单类型应为单程。实际: #{@booking.trip_type}"
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
        offer_prices: @offer_prices,
        cheapest_offer: @cheapest_offer
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @target_date = Date.parse(data['target_date'])
      @origin = data['origin']
      @destination = data['destination']
      @passenger_count = data['passenger_count'] || 1
      @offer_prices = data['offer_prices']
      @cheapest_offer = data['cheapest_offer']
    end
  
    # 模拟 AI Agent 操作：搜索上海到深圳最优惠套餐并预订
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找乘客
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
    
      # 3. 查找最优惠套餐（考虑返现后的最终成本）
      all_offers = FlightOffer.joins(:flight).where(
        flights: {
          departure_city: @origin,
          destination_city: @destination,
          flight_date: @target_date,
          data_version: 0
        },
        data_version: 0
      )
      
      # 按最终成本排序，选择最低的
      target_offer = all_offers.min_by { |o| o.price - o.cashback_amount }
      target_flight = target_offer.flight
    
      # 4. 创建订单（支付全额 offer.price，返现后续到账）
      booking = Booking.create!(
        flight_id: target_flight.id,
        user_id: user.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: target_offer.price,  # 支付全额，不扣除返现
        status: 'pending',
        accept_terms: true,
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_booking',
        booking_id: booking.id,
        flight_number: target_flight.flight_number,
        offer_provider: target_offer.provider_name,
        offer_price: target_offer.price,
        cashback_amount: target_offer.cashback_amount,
        final_cost: target_offer.price - target_offer.cashback_amount,
        passenger_name: passenger.name,
        user_email: user.email
      }
    end
    end
end
