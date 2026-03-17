# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例219: 帮张三预订后天深圳→上海往返航班（后天去程，第4天返程）+上海酒店连续住宿3晚（入住=去程日，退房=返程日），总预算≤3000元
#
# 任务描述：
#   张三后天需要从深圳到上海出差，需要预订往返航班（深圳→上海，3天后返回）和上海酒店住3晚。
#   总预算（去程航班+返程航班+酒店3晚）不超过3000元，Agent需要在预算范围内选择性价比最优的组合。
#   Agent 需要创建1个去程航班订单、1个返程航班订单、1个酒店订单，确保酒店入住日期与去程航班日期一致，
#   返程航班在退房日期或之后，总价格≤3000元。
#
#   ⚠️ 酒店3晚详细说明：
#   - 入住日期 = 去程航班日期（后天，例如3月17日）
#   - 退房日期 = 入住日期 + 3天（例如3月20日）
#   - 住宿时长 = 3晚（第1晚：3月17日→18日，第2晚：3月18日→19日，第3晚：3月19日→20日）
#   - 房间要求 = room_category='overnight'（整晚房型，排除钟点房hourly）
#   - 价格计算 = 单晚房价 × 3晚（例如：239元/晚 × 3 = 717元）
#   - 返程航班必须在退房日期或之后（≥3月20日），确保住满3晚后才离开
#
# 核心要求：
#   - 受益人：张三（使用其姓名、身份证号、电话作为乘客和入住人信息）
#   - 去程日期：后天（Date.current + 2.days）
#   - 路线：深圳 → 上海（往返）
#   - 住宿时长：连续3晚（check_in_date到check_out_date之间的夜数）
#   - 入住日期：等于去程航班日期（去程当天入住）
#   - 退房日期：入住日期 + 3天（住满3晚后退房）
#   - 房间类型：room_category='overnight'（整晚房型，必须排除钟点房）
#   - 返程日期：退房日期或之后（确保住满3晚）
#   - 预算约束：去程+返程+酒店3晚总价 ≤ 3000元
#   - 性价比策略：在预算内选择最优组合（不仅是最便宜，而是性价比最优）
#
# 业务流程（11个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索深圳→上海航班（后天出发）
#   3. 按价格升序排序，获取可选去程航班列表
#   4. 搜索上海→深圳航班（退房日期或之后）
#   5. 按价格升序排序，获取可选返程航班列表
#   6. 搜索上海市区酒店
#   7. 筛选酒店房间（room_category='overnight'，排除钟点房）
#   8. 按房间价格升序排序，获取可选房间列表
#   9. 遍历去程+返程+酒店组合，筛选出总价≤3000元的所有组合
#   10. 在符合预算的组合中，选择性价比最优的组合（预算使用率70-95%，目标80%）
#   11. 创建去程航班订单、返程航班订单、酒店订单（入住日期=去程日期，住3晚）
#
# 复杂度分析（11个关键点）：
#   1. 需要理解往返航班+酒店组合预订场景，并严格控制总预算≤3000元
#   2. 需要明确去程路线（深圳→上海，后天出发）和返程路线（上海→深圳，退房日期或之后）
#   3. 需要协调酒店入住日期与去程航班日期一致（check_in_date = outbound_flight_date）
#   4. 需要精确计算退房日期（check_out_date = check_in_date + 3.days，例如：17日入住→20日退房）
#   5. 需要理解"住3晚"含义：3个完整的夜晚（夜1: 17→18日，夜2: 18→19日，夜3: 19→20日）
#   6. 需要确保返程航班日期在退房日期或之后（return_flight_date >= check_out_date，确保住满3晚）
#   7. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'，CRITICAL要求）
#   8. 需要正确计算酒店总价（单晚房价 × 3晚，例如：239元/晚 × 3 = 717元）
#   9. 需要验证HotelBooking的nights字段等于3（check_out_date - check_in_date = 3天）
#   10. 需要在预算约束下选择最优组合（不仅是最便宜，而是性价比最优）
#   11. 需要使用受益人信息作为航班乘客和酒店入住人
#   ❌ 不能一次性提供所有信息：需要分别查询去程航班、返程航班和酒店数据，遍历所有组合找到最优解，分步骤创建订单。
#
# 评分标准（9项，总计100分）：
#   1. 创建了去程航班订单（15分）
#   2. 创建了返程航班订单（15分）
#   3. 创建了酒店订单（15分）
#   4. 去程航班日期正确（后天）（10分）
#   5. 返程航班日期正确（退房日期或之后）（10分）
#   6. 酒店入住日期正确（后天，去程当天）（5分）
#   7. 酒店住3晚（5分）
#   8. 总价格≤3000元（15分）- 核心业务逻辑
#   9. 乘客/入住人信息正确（张三的姓名、身份证号、电话）（10分）
#
# 验证要点：
#   - 往返航班订单已创建（2个）
#   - 酒店订单已创建（HotelBooking）
#   - 酒店住3晚（check_out_date - check_in_date = 3天）
#   - 去程日期为后天
#   - 返程日期在退房日期或之后（≥check_out_date）
#   - 入住日期为去程航班日期（check_in_date = outbound_flight_date）
#   - 酒店房间类型为整晚房型（room_category = 'overnight'，非hourly）
#   - 总价格≤3000元（去程+返程+酒店3晚总价）
#   - 乘客和入住人信息正确（张三的姓名、身份证号、电话）
#
# 使用方法:
#   rake validator:simulate_single[v219_book_round_trip_budget_2000_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V201V250
  class V219BookRoundTripBudget2000Validator < BaseValidator
    self.validator_id = 'v219_book_round_trip_budget_2000_validator'
    self.task_id = '6fb687fa-7f7f-7f9f-9f0f-8f1a2b3c4d5e'
    self.title = '帮张三预订后天深圳→上海往返航班（后天去程，第4天返程）+上海酒店连续住宿3晚（入住=去程日，退房=返程日），总预算≤3000元'
    self.description = '帮张三订后天从深圳到上海的往返航班+酒店3晚，总预算不超过3000元'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '深圳'
      @destination_city = '上海'
      @nights = 3
      @max_budget = 3000
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 明确使用“后天”作为去程日期
      @outbound_date = Date.current + 2.days  # 后天
      @check_in_date = @outbound_date
      @check_out_date = @check_in_date + @nights.days
      
      # 查找去程航班（后天及之后）
      @outbound_flights = Flight
        .where(departure_city: @origin_city, destination_city: @destination_city, data_version: 0)
        .where('flight_date >= ?', @outbound_date)
        .order(price: :asc)
        .to_a
      
      expect(@outbound_flights).not_to be_empty,
        "数据包缺少#{@origin_city}→#{@destination_city}的航班（日期≥#{@outbound_date}）"
      
      # 查找返程航班（退房日期或之后）
      @return_flights = Flight
        .where(departure_city: @destination_city, destination_city: @origin_city, data_version: 0)
        .where('flight_date >= ?', @check_out_date)
        .order(price: :asc)
        .to_a
      
      # 如果没有适合的返程航班，尝试任何日期大于去程的航班
      if @return_flights.empty?
        @return_flights = Flight
          .where(departure_city: @destination_city, destination_city: @origin_city, data_version: 0)
          .where('flight_date > ?', @outbound_date)
          .order(price: :asc)
          .to_a
      end
      
      # 如果还是没有，就使用所有返程航班
      if @return_flights.empty?
        @return_flights = Flight
          .where(departure_city: @destination_city, destination_city: @origin_city, data_version: 0)
          .order(price: :asc)
          .to_a
      end
      
      expect(@return_flights).not_to be_empty,
        "数据包缺少#{@destination_city}→#{@origin_city}的返程航班"
      
      # 查找酒店
      hotels_relation = Hotel
        .where(city: @destination_city, data_version: 0)
        .order(price: :asc)
      
      expect(hotels_relation.exists?).to be(true), 
        "数据包缺少#{@destination_city}的酒店"
      
      # 计算统计数据（在转换为数组之前）
      hotel_min_price = hotels_relation.joins(:hotel_rooms)
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .minimum('hotel_rooms.price')
      hotel_max_price = hotels_relation.joins(:hotel_rooms)
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .maximum('hotel_rooms.price')
      
      # 转换为数组供后续使用
      @available_hotels = hotels_relation.to_a
      
      # 检查是否有组合满足预算
      cheapest_outbound = @outbound_flights.min_by(&:price).price
      cheapest_return = @return_flights.min_by(&:price).price
      cheapest_hotel_room = @available_hotels.first.hotel_rooms
        .where(data_version: 0, room_category: 'overnight')
        .order(price: :asc).first
      
      if cheapest_hotel_room.nil?
        raise "未找到#{@destination_city}的整晚房型（排除钟点房）"
      end
      
      cheapest_combo = cheapest_outbound + cheapest_return + (cheapest_hotel_room.price * @nights)
      
      if cheapest_combo > @max_budget
        raise "最便宜的组合（去程#{cheapest_outbound}元+返程#{cheapest_return}元+酒店#{cheapest_hotel_room.price * @nights}元=#{cheapest_combo}元）超出预算#{@max_budget}元"
      end
      
      {
        task: "请为#{@passenger.name}预订#{@outbound_date.strftime('%m月%d日')}（后天）从#{@origin_city}到#{@destination_city}的往返航班（#{@check_out_date.strftime('%m月%d日')}或之后返回），并预订#{@destination_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          beneficiary: @passenger.name,
          outbound_route: "#{@origin_city}→#{@destination_city}",
          return_route: "#{@destination_city}→#{@origin_city}",
          outbound_date: @outbound_date.to_s,
          return_date: "≥#{@check_out_date}",
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要综合考虑往返航班和酒店#{@nights}晚的价格，确保总价不超过#{@max_budget}元。优先选择性价比高的组合（预算使用率70-95%）。",
        statistics: {
          available_outbound_flights: @outbound_flights.count,
          available_return_flights: @return_flights.count,
          available_hotels: @available_hotels.count,
          outbound_price_range: {
            min: @outbound_flights.min_by(&:price).price,
            max: @outbound_flights.max_by(&:price).price
          },
          return_price_range: {
            min: @return_flights.min_by(&:price).price,
            max: @return_flights.max_by(&:price).price
          },
          hotel_price_range: {
            min: hotel_min_price,
            max: hotel_max_price
          },
          cheapest_combo: cheapest_combo
        }
      }
    end
    
    def verify
      # 断言1: 创建了往返航班订单（支持两种模式：分开下单或一起下单） (30%)
      add_assertion "创建了往返航班订单（分开下单或一起下单皆可）", weight: 30 do
        # 模式1: 尝试查找round_trip订单（一起下单）
        @booking = Booking
          .includes(:flight, :return_flight)
          .where(data_version: @data_version)
          .where(trip_type: 'round_trip')
          .order(created_at: :desc)
          .to_a
          .find { |b| b.flight&.departure_city == @origin_city && b.flight&.destination_city == @destination_city }
        
        if @booking&.return_flight
          # 找到了round_trip订单，使用模式2
          @booking_mode = :round_trip
        else
          # 模式2: 查找分开下单的两个one_way订单
          all_bookings = Booking
            .includes(:flight)
            .where(data_version: @data_version)
            .where(trip_type: 'one_way')
            .order(created_at: :desc)
            .to_a
          
          @outbound_booking = all_bookings.find do |b|
            b.flight&.departure_city == @origin_city && b.flight&.destination_city == @destination_city
          end
          
          @return_booking = all_bookings.find do |b|
            b.flight&.departure_city == @destination_city && b.flight&.destination_city == @origin_city
          end
          
          if @outbound_booking && @return_booking
            @booking_mode = :separate
          else
            raise "未找到往返航班订单（既无round_trip订单，也无分开的去程+返程订单）"
          end
        end
        
        expect(@booking_mode).to be_in([:round_trip, :separate]), "订单模式识别失败"
      end
      
      return if @booking_mode.nil?
      
      # 断言2: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 去程航班日期正确（后天） (10%)
      add_assertion "去程航班日期正确（#{@outbound_date.strftime('%m月%d日')}）", weight: 10 do
        flight_date = if @booking_mode == :round_trip
                        @booking.flight.flight_date
                      else
                        @outbound_booking.flight.flight_date
                      end
        expect(flight_date).to eq(@outbound_date),
          "去程航班日期错误。期望: #{@outbound_date}（后天）, 实际: #{flight_date}"
      end
      
      # 断言4: 返程航班日期正确（退房日期或之后） (10%)
      add_assertion "返程航班日期正确（≥#{@check_out_date.strftime('%m月%d日')}）", weight: 10 do
        return_date = if @booking_mode == :round_trip
                        @booking.return_flight.flight_date
                      else
                        @return_booking.flight.flight_date
                      end
        expect(return_date).to be >= @check_out_date,
          "返程航班日期错误。期望: ≥#{@check_out_date}（退房日期或之后）, 实际: #{return_date}"
      end
      
      # 断言5: 酒店入住日期正确（后天，去程当天） (5%)
      add_assertion "酒店入住日期正确（#{@check_in_date.strftime('%m月%d日')}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（去程当天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言6: 酒店住3晚 (5%)
      add_assertion "酒店住#{@nights}晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言7: 总价格≤3000元 (15%)
      add_assertion "总价格≤#{@max_budget}元", weight: 15 do
        flight_total_price = if @booking_mode == :round_trip
                               @booking.total_price  # round_trip模式：1个订单包含往返总价
                             else
                               @outbound_booking.total_price + @return_booking.total_price  # separate模式：2个订单价格相加
                             end
        hotel_price = @hotel_booking.total_price
        total_price = flight_total_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。往返航班: #{flight_total_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      # 断言8: 乘客/入住人信息正确（张三） (10%)
      add_assertion "乘客/入住人信息正确（#{@expected_passenger_name}）", weight: 10 do
        # 检查航班乘客
        if @booking_mode == :round_trip
          # round_trip模式：检查1个订单
          expect(@booking.passenger_name).to eq(@expected_passenger_name),
            "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
          expect(@booking.passenger_id_number).to eq(@expected_id_number),
            "航班乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@booking.passenger_id_number}"
        else
          # separate模式：检查2个订单
          expect(@outbound_booking.passenger_name).to eq(@expected_passenger_name),
            "去程航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@outbound_booking.passenger_name}"
          expect(@outbound_booking.passenger_id_number).to eq(@expected_id_number),
            "去程航班乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@outbound_booking.passenger_id_number}"
          expect(@return_booking.passenger_name).to eq(@expected_passenger_name),
            "返程航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@return_booking.passenger_name}"
          expect(@return_booking.passenger_id_number).to eq(@expected_id_number),
            "返程航班乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@return_booking.passenger_id_number}"
        end
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳性价比组合
      best_combo = nil
      best_score = -Float::INFINITY
      target_budget = @max_budget * 0.8  # 目标使用80%预算
      
      # 筛选符合日期要求的航班
      valid_outbound = @outbound_flights.select { |f| f.flight_date == @outbound_date }
      valid_return = @return_flights.select { |f| f.flight_date >= @check_out_date }
      
      valid_outbound.first(5).each do |outbound|
        valid_return.first(5).each do |return_flight|
          @available_hotels.first(5).each do |hotel|
            # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
            # 尝试每个酒店的不同房型（不只是最便宜的）
            hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).limit(3).each do |room|
              total = outbound.price + return_flight.price + (room.price * @nights)
              next if total > @max_budget
              
              # 性价比评分算法（改进版）：
              # 1. 预算使用率分数（期望70-95%，目标80%）
              budget_usage = total.to_f / @max_budget
              budget_score = if budget_usage >= 0.7 && budget_usage <= 0.95
                               100 - ((budget_usage - 0.8).abs * 200)
                             elsif budget_usage < 0.7
                               [0, 50 - ((0.7 - budget_usage) * 200)].max
                             else
                               80
                             end
              
              # 2. 接近目标预算的加分
              proximity_bonus = [0, 20 - ((total - target_budget).abs / @max_budget * 100)].max
              
              # 3. 酒店质量分
              hotel_quality = (room.price.to_f / 300 * 20).clamp(0, 20)
              
              # 综合评分
              value_score = budget_score + proximity_bonus + hotel_quality
              
              if best_combo.nil? || value_score > best_score
                best_combo = { outbound: outbound, return: return_flight, hotel: hotel, room: room, total: total }
                best_score = value_score
              end
            end
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建往返程航班订单（1个订单包含往返两程）
      Booking.create!(
        user: user,
        flight: best_combo[:outbound],           # 去程航班
        return_flight: best_combo[:return],      # 返程航班
        trip_type: 'round_trip',                 # 往返票类型
        return_date: best_combo[:return].flight_date,  # 返程日期
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
        total_price: best_combo[:outbound].price + best_combo[:return].price,  # 往返总价
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_passenger_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: best_combo[:room].price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        origin_city: @origin_city,
        destination_city: @destination_city,
        outbound_date: @outbound_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        max_budget: @max_budget,
        expected_passenger_name: @expected_passenger_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @origin_city = data['origin_city']
      @destination_city = data['destination_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @nights = data['nights']
      @max_budget = data['max_budget']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
    end
  end
end
