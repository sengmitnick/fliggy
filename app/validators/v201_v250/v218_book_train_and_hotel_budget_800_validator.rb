# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例218: 帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚），总预算不超过800元
#
# 任务描述:
#   张三后天需要从上海到杭州出差，需要预订火车票（二等座）和杭州酒店住1晚。
#   要求总预算（火车票+酒店）不超过800元，Agent需要在预算范围内选择性价比最优的组合。
#   Agent 需要创建1个火车票订单和1个酒店订单，确保座位类型为二等座，酒店入住日期与火车日期一致，总价格≤800元。
#
# 业务流程（10个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索上海→杭州火车（后天出发）
#   3. 按二等座价格升序排序，获取可选火车列表
#   4. 搜索杭州市区酒店
#   5. 筛选酒店房间（room_category='overnight'，排除钟点房）
#   6. 按房间价格升序排序，获取可选房间列表
#   7. 遍历火车+酒店组合，筛选出总价≤800元的所有组合
#   8. 在符合预算的组合中，选择性价比最优的组合（预算使用率70-95%，目标80%）
#   9. 创建火车票订单（座位类型=二等座，入住日期=火车日期）
#   10. 创建酒店订单（入住日期=火车日期，入住1晚，退房日期=大后天）
#
# 复杂度分析（9个关键点）：
#   1. 需要理解火车+酒店组合预订场景，并严格控制总预算≤800元
#   2. 需要明确火车路线（上海→杭州，后天出发）
#   3. 需要选择二等座座位类型（seat_type = 'second_class'）
#   4. 需要协调酒店入住日期与火车到达日期一致（check_in_date = train_date）
#   5. 需要计算退房日期（check_out_date = check_in_date + 1.day = 大后天）
#   6. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   7. 需要在预算约束下选择最优组合（不仅是最便宜，而是性价比最优）
#   8. 需要使用受益人信息作为火车乘客和酒店入住人
#   9. 需要验证性价比选择合理（预算使用率60-100%，避免过度浪费预算或选择过低质量服务）
#   ❌ 不能一次性提供所有信息：需要分别查询火车和酒店数据，遍历所有组合找到最优解，分步骤创建订单。
#
# 评分标准（7项，总计100分）：
#   1. 创建了火车票订单（15分）
#   2. 创建了酒店订单（15分）
#   3. 火车出行日期正确（后天）（10分）
#   4. 酒店入住日期正确（后天，火车当天）（10分）
#   5. 总价格≤800元（30分）- 核心业务逻辑
#   6. 性价比选择合理（预算使用率60-100%，避免过度节省或超支）（10分）
#   7. 乘客/入住人信息正确（张三的姓名、身份证号、电话）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v218_book_train_and_hotel_budget_800_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V218BookTrainAndHotelBudget800Validator < BaseValidator
    self.validator_id = 'v218_book_train_and_hotel_budget_800_validator'
    self.task_id = 'c3d4e5f6-7a8b-9c0d-1e2f-3a4b5c6d7e8f'
    self.title = '帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚），总预算不超过800元'
    self.description = '帮张三预订后天上海→杭州火车票（二等座）+杭州酒店（后天入住1晚），总预算不超过800元'
    self.timeout_seconds = 300
    
    def task_description
      "帮张三订后天从上海到杭州的火车票（二等座），预订杭州酒店1晚，总预算不超过800元"
    end
    
    def prepare
      @departure_city = "上海"
      @arrival_city = "杭州"
      @train_date = Date.current + 2.days
      @hotel_city = "杭州"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day
      @max_budget = 800
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 查找可用火车
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)
      
      raise "未找到#{@departure_city}→#{@arrival_city}的火车（#{@train_date}）" if @available_trains.empty?
      
      # 查找可用酒店
      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到#{@hotel_city}的酒店" if @available_hotels.empty?
      
      # 检查是否有组合满足预算
      cheapest_train = @available_trains.first.price_second_class
      cheapest_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      
      if cheapest_hotel_room.nil?
        raise "未找到#{@hotel_city}的整晚房型（排除钟点房）"
      end
      
      cheapest_combo = cheapest_train + cheapest_hotel_room.price
      
      if cheapest_combo > @max_budget
        raise "最便宜的组合(火车#{cheapest_train}元+酒店#{cheapest_hotel_room.price}元=#{cheapest_combo}元)超出预算#{@max_budget}元"
      end
      
      {
        task: "帮张三订后天（#{@train_date.strftime('%Y年%m月%d日')}）从#{@departure_city}到#{@arrival_city}的火车票（二等座），并预订#{@arrival_city}的酒店（当晚入住1晚）。总预算不超过#{@max_budget}元。",
        requirements: {
          beneficiary: '张三',
          train_route: "#{@departure_city}→#{@arrival_city}",
          train_date: @train_date.to_s,
          seat_type: '二等座',
          hotel_city: @hotel_city,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 1,
          max_budget: @max_budget
        },
        hint: "需要综合考虑火车票和酒店的价格，确保总价不超过#{@max_budget}元。优先选择性价比高的组合（预算使用率70-95%）。",
        statistics: {
          available_trains: @available_trains.count,
          available_hotels: @available_hotels.count,
          train_price_range: {
            min: @available_trains.minimum(:price_second_class),
            max: @available_trains.maximum(:price_second_class)
          },
          hotel_price_range: {
            min: @available_hotels.joins(:hotel_rooms).where(hotel_rooms: { data_version: 0, room_category: 'overnight' }).minimum('hotel_rooms.price'),
            max: @available_hotels.joins(:hotel_rooms).where(hotel_rooms: { data_version: 0, room_category: 'overnight' }).maximum('hotel_rooms.price')
          },
          cheapest_combo: cheapest_combo
        }
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 15 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @hotel_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@hotel_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "火车出行日期正确（#{@train_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@train_booking.train.departure_time.to_date).to eq(@train_date),
          "火车出行日期错误。期望: #{@train_date}（后天）, 实际: #{@train_booking.train.departure_time.to_date}"
      end
      
      add_assertion "酒店入住日期正确（#{@check_in_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（火车到达当天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "总价格≤#{@max_budget}元（核心要求）", weight: 30 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。火车票: #{train_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "性价比选择合理", weight: 10 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        budget_usage = (total_price.to_f / @max_budget * 100).round(1)
        
        # 期望使用预算的60%-100%（既不浪费预算，也要控制在限额内）
        expect(budget_usage).to be >= 60,
          "预算使用率过低（#{budget_usage}%），可能未充分利用预算选择更好的服务。总价: #{total_price}元, 预算: #{@max_budget}元"
        expect(budget_usage).to be <= 100,
          "预算使用率超限（#{budget_usage}%）。总价: #{total_price}元, 预算: #{@max_budget}元"
      end
      
      add_assertion "乘客/入住人信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车票乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳性价比组合
      best_combo = nil
      best_score = -Float::INFINITY
      target_budget = @max_budget * 0.8 # 目标使用80%预算
      
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
          # 尝试每个酒店的不同房型（不只是最便宜的）
          hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).limit(3).each do |room|
            total = train.price_second_class + room.price
            next if total > @max_budget
            
            # 性价比评分算法（改进版）：
            # 1. 预算使用率分数（期望70-95%，目标80%）
            budget_usage = total.to_f / @max_budget
            budget_score = if budget_usage >= 0.7 && budget_usage <= 0.95
                             # 在70-95%范围内，越接近80%越好
                             100 - ((budget_usage - 0.8).abs * 200) # 最佳点80%
                           elsif budget_usage < 0.7
                             # 低于70%严重扣分
                             [0, 50 - ((0.7 - budget_usage) * 200)].max
                           else
                             # 95-100%也可接受，略微扣分
                             80
                           end
            
            # 2. 接近目标预算的加分（鼓励充分利用预算）
            proximity_bonus = [0, 20 - ((total - target_budget).abs / @max_budget * 100)].max
            
            # 3. 酒店质量分（价格越高通常质量越好）
            hotel_quality = (room.price.to_f / 300 * 20).clamp(0, 20)
            
            # 综合评分
            value_score = budget_score + proximity_bonus + hotel_quality
            
            if best_combo.nil? || value_score > best_score
              best_combo = { train: train, hotel: hotel, room: room, total: total }
              best_score = value_score
            end
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建火车票订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id,
        contact_phone: @expected_phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:train].price_second_class,
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
        guest_name: @expected_passenger_name,
        guest_phone: @expected_phone,
        payment_method: '花呗',
        total_price: best_combo[:room].price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date.to_s,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_budget = data['max_budget']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @hotel_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
