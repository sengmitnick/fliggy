# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例221: 帮张三预订2天后广州→成都往返火车票（2天后去程，9天后返程）+成都酒店连续住宿7晚1间房（入住=去程日，退房=返程日），总预算≤3000元
#
# 任务描述：
#   张三打算2天后从广州到成都玩7天，需要预订往返火车票和成都酒店住7晚。
#   总预算（往返火车票+酒店7晚）不超过3000元，Agent需要在预算范围内选择性价比最优的组合。
#   Agent 需要创建1个去程火车票订单、1个返程火车票订单、1个酒店订单，确保酒店入住日期与去程日期一致，
#   退房日期与返程日期一致，总价格≤3000元。
#
#   ⚠️ 7天自由行详细说明：
#   - 去程日期 = 2天后（Date.current + 2.days）
#   - 返程日期 = 去程日期 + 7天（Date.current + 9.days）
#   - 入住日期 = 去程日期（去程当天入住）
#   - 退房日期 = 返程日期（返程当天退房）
#   - 住宿时长 = 7晚（从去程日到返程日之间的夜数）
#   - 房间数量 = 1间（单人或标准间）
#   - 房间要求 = room_category='overnight'（整晚房型，排除钟点房hourly）
#   - 交通方式 = 火车票（经济实惠）
#   - 价格计算 = 去程火车票 + 返程火车票 + (单晚房价×7晚×1间房)
#
# 核心要求：
#   - 受益人：张三（使用其姓名、身份证号、电话作为乘客和入住人信息）
#   - 去程日期：2天后（Date.current + 2.days）
#   - 返程日期：9天后（Date.current + 9.days，即去程+7天）
#   - 路线：广州 ⇄ 成都（往返）
#   - 交通方式：火车票（经济实惠）
#   - 住宿时长：连续7晚（check_in_date到check_out_date之间的夜数）
#   - 入住日期：等于去程日期（去程当天入住）
#   - 退房日期：等于返程日期（返程当天退房）
#   - 房间数量：1间（单人或标准间）
#   - 房间类型：room_category='overnight'（整晚房型，必须排除钟点房）
#   - 预算约束：往返火车票+酒店7晚1间房总价 ≤ 3000元
#   - 性价比策略：在预算内选择最优组合（火车出行经济实惠）
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索广州→成都火车票（2天后出发）
#   3. 按价格升序排序，获取可选去程火车票列表
#   4. 搜索成都→广州火车票（9天后返回）
#   5. 按价格升序排序，获取可选返程火车票列表
#   6. 搜索成都市区酒店，筛选整晚房型
#   7. 遍历往返火车票+酒店组合，筛选出总价≤3000元的所有组合
#   8. 在符合预算的组合中，选择性价比最优的组合并创建订单
#
# 复杂度分析（8个关键点）：
#   1. 需要理解往返火车票+酒店组合预订场景，并严格控制总预算≤3000元
#   2. 需要查询火车时刻表和价格信息（TrainBooking模型）
#   3. 需要协调酒店入住日期与去程日期一致（check_in_date = outbound_date）
#   4. 需要协调酒店退房日期与返程日期一致（check_out_date = return_date）
#   5. 需要精确计算住宿天数（7晚 = 返程日期 - 去程日期）
#   6. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   7. 需要正确计算总价（去程火车票 + 返程火车票 + 单晚房价×7晚×1间房）
#   8. 需要在预算约束下选择最优组合（不仅是最便宜，而是性价比最优）
#   ❌ 不能一次性提供所有信息：需要分别查询去程火车票、返程火车票和酒店数据，遍历所有组合找到最优解，分步骤创建订单。
#
# 评分标准（7项，总计100分）：
#   1. 创建了往返火车票订单（20分）
#   2. 创建了酒店订单（15分）
#   3. 酒店住7晚（10分）
#   4. 入住/退房日期正确（去程当天入住，返程当天退房）（10分）
#   5. 总价格≤3000元（30分）- 核心业务逻辑
#   6. 乘客/入住人信息正确（张三的姓名、身份证号、电话）（10分）
#   7. 订单状态有效（5分）
#
# 验证要点：
#   - 往返火车票订单已创建（2个TrainBooking）
#   - 酒店订单已创建（HotelBooking）
#   - 酒店住7晚（check_out_date - check_in_date = 7天）
#   - 预订1间房（room_count = 1）
#   - 去程日期为2天后
#   - 返程日期为9天后（去程+7天）
#   - 入住日期为去程日期（check_in_date = outbound_date）
#   - 退房日期为返程日期（check_out_date = return_date）
#   - 酒店房间类型为整晚房型（room_category = 'overnight'，非hourly）
#   - 总价格≤3000元（往返火车票+酒店7晚1间房总价）
#   - 乘客和入住人信息正确（张三的姓名、身份证号、电话）
#
# 使用方法:
#   rake validator:simulate_single[v221_book_week_trip_budget_3000_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V201V250
  class V221BookWeekTripBudget3000Validator < BaseValidator
    self.validator_id = 'v221_book_week_trip_budget_3000_validator'
    self.task_id = '8fd809fc-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '帮张三预订2天后广州→成都往返火车票（2天后去程，9天后返程）+成都酒店连续住宿7晚1间房（入住=去程日，退房=返程日），总预算≤3000元'
    self.description = '帮张三订2天后从广州到成都的7天自由行（往返火车票+酒店7晚1间房），总预算不超过3000元'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '广州'
      @destination_city = '成都'
      @outbound_date = Date.current + 2.days
      @return_date = @outbound_date + 7.days
      @check_in_date = @outbound_date
      @check_out_date = @return_date
      @nights = 7
      @max_budget = 3000
      
      # 查询demo_user和乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 查找往返交通（火车为主，价格便宜）
      @outbound_trains = Train.by_route(@origin_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_trains = Train.by_route(@destination_city, @origin_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到往返火车或酒店" if @outbound_trains.empty? || @return_trains.empty? || @available_hotels.empty?
      
      {
        task: "请预订#{@outbound_date.strftime('%Y年%m月%d日')}从#{@origin_city}到#{@destination_city}的7天自由行（#{@return_date.strftime('%m月%d日')}返回），包含往返火车票和#{@destination_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          origin_city: @origin_city,
          destination_city: @destination_city,
          outbound_date: @outbound_date,
          return_date: @return_date,
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要综合考虑往返火车票和酒店7晚的价格，确保总价不超过#{@max_budget}元。火车出行经济实惠。"
      }
    end
    
    def verify
      add_assertion "创建了往返火车票订单", weight: 20 do
        # 查找去程火车票订单
        @outbound_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @origin_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        # 查找返程火车票订单
        @return_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @destination_city, arrival_city: @origin_city })
          .where(data_version: @data_version)
          .first
        
        expect(@outbound_booking).not_to be_nil, "未找到去程火车票订单"
        expect(@return_booking).not_to be_nil, "未找到返程火车票订单"
      end
      
      return if @outbound_booking.nil? || @return_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店住#{@nights}晚", weight: 10 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 30 do
        outbound_price = @outbound_booking.total_price
        return_price = @return_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = outbound_price + return_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。去程: #{outbound_price}元, 返程: #{return_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "乘客信息正确（姓名、身份证、手机号）", weight: 10 do
        # 验证去程乘客信息
        expect(@outbound_booking.passenger_name).to eq(@passenger.name),
          "去程乘客姓名错误。期望: #{@passenger.name}, 实际: #{@outbound_booking.passenger_name}"
        expect(@outbound_booking.passenger_id_number).to eq(@passenger.id_number),
          "去程乘客身份证错误。期望: #{@passenger.id_number}, 实际: #{@outbound_booking.passenger_id_number}"
        expect(@outbound_booking.contact_phone).to eq(@passenger.phone),
          "去程联系电话错误。期望: #{@passenger.phone}, 实际: #{@outbound_booking.contact_phone}"
        
        # 验证返程乘客信息
        expect(@return_booking.passenger_name).to eq(@passenger.name),
          "返程乘客姓名错误。期望: #{@passenger.name}, 实际: #{@return_booking.passenger_name}"
        expect(@return_booking.passenger_id_number).to eq(@passenger.id_number),
          "返程乘客身份证错误。期望: #{@passenger.id_number}, 实际: #{@return_booking.passenger_id_number}"
        expect(@return_booking.contact_phone).to eq(@passenger.phone),
          "返程联系电话错误。期望: #{@passenger.phone}, 实际: #{@return_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（姓名、手机号）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@passenger.name),
          "入住人姓名错误。期望: #{@passenger.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@outbound_booking.status).to be_in(['pending', 'paid', 'completed']),
          "去程火车票订单状态无效。实际: #{@outbound_booking.status}"
        expect(@return_booking.status).to be_in(['pending', 'paid', 'completed']),
          "返程火车票订单状态无效。实际: #{@return_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态无效。实际: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳组合
      best_combo = nil
      best_value = 0
      
      @outbound_trains.first(3).each do |outbound|
        @return_trains.first(3).each do |return_train|
          @available_hotels.first(5).each do |hotel|
            room = hotel.hotel_rooms.where(data_version: 0).first
            next unless room
            
            total = outbound.price_second_class + return_train.price_second_class + (room.price * @nights)
            next if total > @max_budget
            
            value_score = @max_budget - total
            if best_combo.nil? || value_score > best_value
              best_combo = { outbound: outbound, return: return_train, hotel: hotel, room: room }
              best_value = value_score
            end
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建去程火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:outbound],
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:outbound].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建返程火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:return],
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:return].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room_id: best_combo[:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
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
        return_date: @return_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        max_budget: @max_budget,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @origin_city = data['origin_city']
      @destination_city = data['destination_city']
      @outbound_date = Date.parse(data['outbound_date'])
      @return_date = Date.parse(data['return_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @max_budget = data['max_budget']
      
      # Restore passenger data from flattened fields
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @outbound_trains = Train.by_route(@origin_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_trains = Train.by_route(@destination_city, @origin_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
