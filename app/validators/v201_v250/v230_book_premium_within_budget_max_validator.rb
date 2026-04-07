# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例230: 帮张三预订5天后广州→杭州交通+酒店（住1晚），要求总价≤2000元，服务档次最高（优先酒店评分）
#
# 任务描述:
#   张三有固定预算2000元，想5天后从广州去杭州出差，需要在预算内选择服务档次最高的组合，
#   优先考虑酒店评分（评分越高档次越高），交通可以选航班或火车。
#
# 业务流程（10个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 明确预算约束（总预算≤2000元）
#   3. 查询交通选项（广州→杭州，5天后出发，包括航班和火车二等座）
#   4. 查询酒店选项（杭州，5天后入住，住1晚）
#   5. 枚举所有交通+酒店组合（航班×酒店 + 火车×酒店）
#   6. 过滤预算内组合（交通价格 + 酒店价格 ≤ 2000元）
#   7. 对预算内组合按酒店评分排序（评分越高档次越高）
#   8. 选择酒店评分最高的组合
#   9. 创建交通订单（5天后出发的航班或火车票）
#   10. 创建酒店订单（5天后入住，住1晚）
#
# 复杂度分析（10个关键点）：
#   1. 预算约束优化：需要在硬预算约束下找到最优解（约束优化问题）
#   2. 组合空间搜索：需要枚举 (航班数量+火车数量) × 酒店数量 的所有组合
#   3. 多类型交通处理：航班和火车使用不同的价格字段（price vs price_second_class）
#   4. 档次评估标准：需要明确定义"档次"（这里用酒店评分作为质量指标）
#   5. 预算边界判断：严格执行 ≤ 预算上限，避免超支
#   6. 质量优先策略：在预算内优先选择高评分酒店，交通只是配角
#   7. 参考值计算：prepare阶段需要预计算预算内最高酒店评分作为参考
#   8. 误差容忍设计：允许0.5星偏差，避免因微小差异导致验证失败
#   9. 日期对齐处理：交通日期和酒店入住日期都是5天后（Date.current + 5.days）
#   10. 用户信息统一：确保张三的姓名、身份证、手机号在交通和酒店订单中一致
#
# 评分标准（9项，总计100分）：
#   - 断言1: 创建了交通订单（航班或火车） (15分)
#   - 断言2: 创建了酒店订单 (15分)
#   - 断言3: 出行日期正确（5天后） (10分)
#   - 断言4: 酒店入住日期正确（5天后入住，第6天退房） (10分)
#   - 断言5: 乘客信息正确（张三的姓名、身份证、手机号） (5分)
#   - 断言6: 入住人信息正确（张三的姓名、手机号） (5分)
#   - 断言7: 总价格≤2000元预算上限 (15分)
#   - 断言8: 在预算内选择了酒店评分最高或接近最高的组合（允许0.5星偏差） (20分)
#   - 断言9: 订单状态有效 (5分)
module V201V250
  class V230BookPremiumWithinBudgetMaxValidator < BaseValidator
    self.validator_id = 'v230_book_premium_within_budget_max_validator'
    self.task_id = '6ff687ff-7f7f-7f9f-9f0f-8f1a2b3c4d5f'
    self.title = '帮张三预订5天后广州→杭州交通+酒店（住1晚），要求总价≤2000元，服务档次最高（优先酒店评分）'
    self.description = '张三有固定预算2000元，想5天后从广州去杭州出差，需要在预算内选择服务档次最高的组合，优先考虑酒店评分'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '杭州'
      @max_budget = 2000
      @travel_date = Date.current + 5.days  # 5天后
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      # 预查询乘客信息（张三）
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = demo_user.passengers.find_by!(is_self: true)  # RLS 自动注入 data_version
      @expected_passenger_name = demo_passenger.name  # 张三
      @expected_passenger_id = demo_passenger.id_number
      @expected_phone = demo_passenger.phone
      @expected_guest_name = demo_passenger.name  # 统一使用张三作为入住人
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
      
      raise "未找到交通或酒店" if (@available_flights.empty? && @available_trains.empty?) || @available_hotels.empty?
      
      # 计算预算内最高评分参考值
      best_quality_in_budget = 0
      @available_flights.each do |f|
        @available_hotels.each do |h|
          room = h.hotel_rooms.where(data_version: 0).first
          next unless room
          total = f.price + h.price
          next if total > @max_budget
          quality = h.rating  # 用酒店评分作为质量指标
          best_quality_in_budget = [best_quality_in_budget, quality].max
        end
      end
      
      @available_trains.each do |t|
        @available_hotels.each do |h|
          room = h.hotel_rooms.where(data_version: 0).first
          next unless room
          total = t.price_second_class + h.price
          next if total > @max_budget
          quality = h.rating
          best_quality_in_budget = [best_quality_in_budget, quality].max
        end
      end
      
      @reference_quality = best_quality_in_budget
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的交通和酒店（住1晚），总预算≤#{@max_budget}元，在预算内选择服务档次最高的组合（优先考虑酒店评分）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          max_budget: "≤#{@max_budget}元",
          optimization: '预算内最高档次'
        },
        hint: "预算有限#{@max_budget}元，优先选择高评分酒店，交通可以选航班或火车。"
      }
    end
    
    def verify
      add_assertion "创建了交通订单（航班或火车）", weight: 15 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @transport_booking = @flight_booking || @train_booking
        @transport_type = @flight_booking ? 'flight' : 'train'
        expect(@transport_booking).not_to be_nil, "未找到交通订单"
      end
      
      return if @transport_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "出行日期正确（5天后#{@travel_date}）", weight: 10 do
        if @transport_type == 'flight'
          expect(@transport_booking.flight.flight_date).to eq(@travel_date),
            "航班日期错误。期望: #{@travel_date}, 实际: #{@transport_booking.flight.flight_date}"
        else
          train_date = @transport_booking.train.departure_time.to_date
          expect(train_date).to eq(@travel_date),
            "火车日期错误。期望: #{@travel_date}, 实际: #{train_date}"
        end
      end
      
      add_assertion "酒店入住日期正确（5天后入住#{@check_in_date}，第6天退房#{@check_out_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘客信息正确（张三的姓名、身份证、手机号）", weight: 5 do
        expect(@transport_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transport_booking.passenger_name}"
        expect(@transport_booking.passenger_id_number).to eq(@expected_passenger_id),
          "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@transport_booking.passenger_id_number}"
        expect(@transport_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@transport_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三的姓名、手机号）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 15 do
        transport_price = @transport_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = transport_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。交通: #{transport_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "在预算内选择了酒店评分最高或接近最高的组合（允许0.5星偏差）", weight: 20 do
        hotel = @hotel_booking.hotel
        actual_quality = hotel.rating
        
        # 允许0.5星的偏差
        expect(actual_quality).to be >= @reference_quality - 0.5,
          "未选择预算内最高档次。预算内最高酒店评分: #{@reference_quality}星, 实际选择酒店评分: #{actual_quality}星"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@transport_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 在预算内找到评分最高的组合
      best_combo = nil
      best_quality = 0
      
      # 尝试航班组合
      @available_flights.each do |flight|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = flight.price + room.price
          next if total > @max_budget
          
          quality = hotel.rating
          if quality > best_quality
            best_quality = quality
            best_combo = { type: :flight, transport: flight, hotel: hotel, room: room }
          end
        end
      end
      
      # 尝试火车组合
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = train.price_second_class + room.price
          next if total > @max_budget
          
          quality = hotel.rating
          if quality > best_quality
            best_quality = quality
            best_combo = { type: :train, transport: train, hotel: hotel, room: room }
          end
        end
      end
      
      raise "未找到预算内的组合" if best_combo.nil?
      
      # 创建交通订单
      if best_combo[:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:transport],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          total_price: best_combo[:transport].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:transport],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:transport].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: best_combo[:room].price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget,
        reference_quality: @reference_quality,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone,
        expected_guest_name: @expected_guest_name
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_budget = data['max_budget'].to_i
      @reference_quality = data['reference_quality'].to_f
      
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      @expected_guest_name = data['expected_guest_name']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
    end
  end
end
