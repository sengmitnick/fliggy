# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例220: 帮张三预订3天后北京→三亚单程航班（张三+李四+小明）+三亚酒店连续住宿2晚1间房（入住=航班当天），总预算≤5000元
#
# 任务描述：
#   张三需要带家人（李四、小明）3天后从北京到三亚旅行，需要预订单程航班和三亚酒店住2晚。
#   总预算（3人机票+酒店2晚）不超过5000元，Agent需要在预算范围内选择性价比最优的组合。
#   Agent 需要为2大1小各创建1个航班订单（共3个订单），创建1个酒店订单，确保酒店入住日期与航班日期一致，
#   总价格≤5000元。
#
#   ⚠️ 家庭出行详细说明：
#   - 航班日期 = 3天后（Date.current + 3.days）
#   - 乘客组成 = 2大人（张三+李四）+ 1儿童（小明）
#   - 入住日期 = 航班日期（航班当天入住）
#   - 退房日期 = 入住日期 + 2天
#   - 住宿时长 = 2晚（第1晚：航班当天→次日，第2晚：次日→第3天）
#   - 房间数量 = 1间（家庭房，可容纳2大1小）
#   - 房间要求 = room_category='overnight'（整晚房型，排除钟点房hourly）
#   - 价格计算 = (成人票价×2 + 儿童票价×1) + (单晚房价×2晚×1间房)
#
# 核心要求：
#   - 受益人：张三、李四、小明（3人）
#   - 航班日期：3天后（Date.current + 3.days）
#   - 路线：北京 → 三亚（单程）
#   - 乘客组成：2大人（张三+李四）+ 1儿童（小明）
#   - 住宿时长：连续2晚（check_in_date到check_out_date之间的夜数）
#   - 入住日期：等于航班日期（航班当天入住）
#   - 退房日期：入住日期 + 2天（住满2晚后退房）
#   - 房间数量：1间（家庭房，可容纳2大1小）
#   - 房间类型：room_category='overnight'（整晚房型，必须排除钟点房）
#   - 预算约束：3人机票+酒店2晚1间房总价 ≤ 5000元
#   - 性价比策略：在预算内选择最优组合（不仅是最便宜，而是性价比最优）
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三、李四、小明，使用其姓名、身份证号、电话）
#   2. 搜索北京→三亚航班（3天后出发）
#   3. 按价格升序排序，获取可选航班列表
#   4. 搜索三亚市区酒店
#   5. 筛选酒店房间（room_category='overnight'，排除钟点房）
#   6. 按房间价格升序排序，获取可选房间列表
#   7. 遍历航班+酒店组合，筛选出总价≤5000元的所有组合（3人机票+酒店2晚）
#   8. 在符合预算的组合中，选择性价比最优的组合并创建订单（3个航班订单+1个酒店订单）
#
# 复杂度分析（8个关键点）：
#   1. 需要理解家庭出行场景（张三+李四+小明），为每个人创建独立的航班订单
#   2. 需要明确航班路线（北京→三亚，3天后出发）
#   3. 需要协调酒店入住日期与航班日期一致（check_in_date = flight_date）
#   4. 需要精确计算退房日期（check_out_date = check_in_date + 2.days）
#   5. 需要理解"住2晚"含义：2个完整的夜晚
#   6. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   7. 需要正确计算总价（3人机票总价 + 单晚房价×2晚×1间房）
#   8. 需要在预算约束下选择最优组合（不仅是最便宜，而是性价比最优）
#   ❌ 不能一次性提供所有信息：需要分别查询航班和酒店数据，遍历所有组合找到最优解，分步骤创建订单。
#
# 评分标准（7项，总计100分）：
#   1. 创建了航班订单（至少3个，对应张三+李四+小明）（30分）- 核心业务逻辑
#   2. 创建了酒店订单（15分）
#   3. 航班日期正确（3天后）（10分）
#   4. 酒店入住日期正确（航班当天）（10分）
#   5. 总价格≤5000元（15分）- 核心业务逻辑
#   6. 乘客/入住人信息正确（张三、李四、小明）（10分）
#   7. 订单状态有效（10分）
#
# 验证要点：
#   - 航班订单已创建（至少3个，对应张三+李四+小明）
#   - 酒店订单已创建（HotelBooking）
#   - 酒店住2晚（check_out_date - check_in_date = 2天）
#   - 预订1间房（room_count = 1）
#   - 航班日期为3天后
#   - 入住日期为航班日期（check_in_date = flight_date）
#   - 酒店房间类型为整晚房型（room_category = 'overnight'，非hourly）
#   - 总价格≤5000元（3人机票+酒店2晚1间房总价）
#   - 乘客信息正确（张三、李四作为成人乘客，小明作为儿童乘客）
#   - 订单状态有效
#
# 使用方法:
#   rake validator:simulate_single[v220_book_family_trip_budget_5000_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V201V250
  class V220BookFamilyTripBudget5000Validator < BaseValidator
    self.validator_id = 'v220_book_family_trip_budget_5000_validator'
    self.task_id = '7fc798fb-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '帮张三预订3天后北京→三亚单程航班（张三+李四+小明）+三亚酒店连续住宿2晚（入住=航班当天），总预算≤5000元'
    self.description = '帮张三订3天后从北京到三亚的单程航班（张三、李四、小明）+酒店2晚，总预算不超过5000元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '三亚'
      @flight_date = Date.current + 3.days
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 2.days
      @nights = 2
      @adults = 2
      @children = 1
      @max_budget = 5000
      
      # 预查询乘客信息（张三、李四、小明）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_adult_names = [@zhangsan.name, @lisi.name]  # 2个成人
      @expected_child_name = '小明'  # 1个儿童
      @expected_id_numbers = {
        @zhangsan.name => @zhangsan.id_number,
        @lisi.name => @lisi.id_number
      }
      @expected_phones = {
        @zhangsan.name => @zhangsan.phone,
        @lisi.name => @lisi.phone
      }
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(price: :asc)
      
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      {
        task: "请为张三、李四、小明预订#{@flight_date.strftime('%m月%d日')}（3天后）从#{@departure_city}到#{@arrival_city}的单程航班，并预订#{@arrival_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          passengers: '张三、李四、小明（2大1小）',
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要为张三、李四、小明预订机票和酒店，确保总价不超过#{@max_budget}元。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (30分) - 核心评分项
      add_assertion "创建了航班订单", weight: 30 do
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .to_a
        
        expect(@flight_bookings).not_to be_empty, "未找到航班订单"
      end
      
      return if @flight_bookings.empty?
      
      # 断言2: 创建了酒店订单 (15分)
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 航班日期正确（3天后） (10分)
      add_assertion "航班日期正确（#{@flight_date.strftime('%m月%d日')}）", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.flight.flight_date).to eq(@flight_date),
            "航班日期错误。期望: #{@flight_date}（3天后）, 实际: #{booking.flight.flight_date}"
        end
      end
      
      # 断言4: 酒店入住日期正确（航班当天） (10分)
      add_assertion "酒店入住日期正确（#{@check_in_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言5: 总价格≤#{@max_budget}元 (15分) - 核心评分项
      add_assertion "总价格≤#{@max_budget}元", weight: 15 do
        flight_total = @flight_bookings.sum(&:total_price)
        hotel_price = @hotel_booking.total_price
        total_price = flight_total + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。航班: #{flight_total}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      # 断言6: 乘客/入住人信息正确（张三、李四、小明） (10分)
      add_assertion "乘客/入住人信息正确（张三、李四、小明）", weight: 10 do
        passenger_names = @flight_bookings.map(&:passenger_name)
        zhangsan_count = passenger_names.count('张三')
        lisi_count = passenger_names.count('李四')
        child_count = passenger_names.count(@expected_child_name)
        
        expect(zhangsan_count).to be >= 1, "未找到张三的航班订单。实际乘客: #{passenger_names.join('、')}"
        expect(lisi_count).to be >= 1, "未找到李四的航班订单。实际乘客: #{passenger_names.join('、')}"
        expect(child_count).to be >= 1, "未找到#{@expected_child_name}的航班订单。实际乘客: #{passenger_names.join('、')}"
        expect(@expected_adult_names).to include(@hotel_booking.guest_name),
          "酒店入住人姓名错误。期望: 张三或李四, 实际: #{@hotel_booking.guest_name}"
      end
      
      # 断言7: 订单状态有效 (10分)
      add_assertion "订单状态有效", weight: 10 do
        @flight_bookings.each { |b| expect(b.status).to be_in(['pending', 'paid', 'completed']) }
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的组合（简化处理：3人都订同一航班）
      best_combo = nil
      best_value = 0
      
      @available_flights.first(5).each do |flight|
        @available_hotels.first(5).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          # 3人机票 + 酒店2晚
          total = (flight.price * 3) + (room.price * @nights)
          next if total > @max_budget
          
          value_score = @max_budget - total
          if best_combo.nil? || value_score > best_value
            best_combo = { flight: flight, hotel: hotel, room: room }
            best_value = value_score
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建航班订单（为张三、李四、小明各创建一个订单）
      passengers = [
        { name: @zhangsan.name, id_number: @zhangsan.id_number, phone: @zhangsan.phone },
        { name: @lisi.name, id_number: @lisi.id_number, phone: @lisi.phone },
        { name: @expected_child_name, id_number: @zhangsan.id_number, phone: @zhangsan.phone }  # 儿童使用张三的身份证和电话
      ]
      
      passengers.each do |passenger|
        Booking.create!(
          user: user,
          flight: best_combo[:flight],
          passenger_name: passenger[:name],
          passenger_id_number: passenger[:id_number],
          contact_phone: passenger[:phone],
          total_price: best_combo[:flight].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 创建酒店订单（使用张三作为入住人）
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @zhangsan.name,
        guest_phone: @zhangsan.phone,
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
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        adults: @adults,
        children: @children,
        max_budget: @max_budget,
        expected_adult_names: @expected_adult_names,
        expected_child_name: @expected_child_name,
        expected_id_numbers: @expected_id_numbers,
        expected_phones: @expected_phones
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @adults = data['adults']
      @children = data['children']
      @max_budget = data['max_budget']
      @expected_adult_names = data['expected_adult_names']
      @expected_child_name = data['expected_child_name']
      @expected_id_numbers = data['expected_id_numbers']
      @expected_phones = data['expected_phones']
      
      # 重新加载乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(price: :asc)
      
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
