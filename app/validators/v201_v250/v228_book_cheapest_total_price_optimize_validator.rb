# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例228: 帮张三预订3天后上海→北京往返交通（航班或火车）+北京酒店（住2晚），总价最低组合优化
#
# 任务描述:
#   张三3天后要从上海去北京出差2天，需要预订往返交通（可以是航班或火车）和酒店住2晚，
#   希望选择总价最低的组合（去程交通+返程交通+酒店2晚的总价最优）。
#
# 业务流程（10个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 查询去程交通选项（上海→北京，3天后，包括航班和火车二等座）
#   3. 查询返程交通选项（北京→上海，第5天返回，即去程后2天，包括航班和火车二等座）
#   4. 查询北京酒店选项（目的地城市）
#   5. 计算所有可能的组合总价（去程+返程+酒店2晚）
#   6. 识别总价最低的组合方案（可以是航班+火车、火车+航班、全航班、全火车等混合组合）
#   7. 创建去程交通订单（航班订单或火车订单，取决于最优组合）
#   8. 创建返程交通订单（航班订单或火车订单，取决于最优组合）
#   9. 创建酒店订单（选择最优组合中的酒店，入住2晚）
#   10. 确认订单状态有效（pending/paid/completed）
#
# 复杂度分析（10个关键点）：
#   1. 多维度交通选择：去程和返程各有航班、火车两种交通方式，需要全局优化
#   2. 组合爆炸问题：需要计算 (去程航班+去程火车) × (返程航班+返程火车) × 酒店数量 的所有组合
#   3. 总价计算逻辑：总价 = 去程价格 + 返程价格 + 酒店价格×2晚
#   4. 多表订单创建：需要根据最优组合类型，创建不同的订单表（Booking表用于航班，TrainBooking表用于火车）
#   5. 条件分支处理：verify方法需要判断去程/返程是航班还是火车，执行不同的验证逻辑
#   6. 数据源一致性：所有查询必须过滤data_version=0确保数据隔离
#   7. 日期管理：涉及去程日期（+3天）、返程日期（+5天）、入住日期（+3天）、退房日期（+5天）
#   8. 乘客信息复用：去程、返程、酒店订单都需要使用同一受益人的信息
#   9. 理论最低价计算：需要单独计算去程最低、返程最低、酒店最低，作为验证基准
#   10. 状态恢复复杂度：需要恢复日期、乘客信息、并重新查询4类数据源（去程航班/火车、返程航班/火车、酒店）
#
# 评分标准（10项，总计100分）：
#   - 断言1: 创建了去程交通订单（航班或火车） (10分)
#   - 断言2: 创建了返程交通订单（航班或火车） (10分)
#   - 断言3: 创建了酒店订单 (10分)
#   - 断言4: 去程日期正确（3天后） (5分)
#   - 断言5: 返程日期正确（第5天，即去程后2天） (5分)
#   - 断言6: 酒店入住日期正确（入住3天后，退房5天后） (5分)
#   - 断言7: 去程和返程乘客信息正确（张三的姓名、身份证号、手机号） (5分)
#   - 断言8: 入住人信息正确（张三的姓名、手机号） (5分)
#   - 断言9: 选择了总价最低或接近最低的组合（实际总价≤理论最低价×1.2，允许20%偏差） (35分)
#   - 断言10: 订单状态有效（去程、返程、酒店订单状态均为pending/paid/completed） (10分)
#
# 使用方法:
#   rake validator:simulate_single[v228_book_cheapest_total_price_optimize_validator]
module V201V250
  class V228BookCheapestTotalPriceOptimizeValidator < BaseValidator
    self.validator_id = 'v228_book_cheapest_total_price_optimize_validator'
    self.task_id = 'b2c3d4e5-6f7a-8b9c-0d1e-2f3a4b5c6d7e'
    self.title = '帮张三预订3天后上海→北京往返交通（航班或火车）+北京酒店（住2晚），总价最低组合优化'
    self.description = '张三3天后要从上海去北京出差2天，需要预订往返交通（可以是航班或火车）和酒店住2晚，希望总价最低'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '北京'
      @outbound_date = Date.today + 3.days
      @return_date = @outbound_date + 2.days  # 第5天返回（今天+5天）
      @check_in_date = @outbound_date
      @check_out_date = @return_date
      
      # 预查询乘客信息（张三）
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @expected_passenger_name = demo_passenger.name  # 张三
      @expected_passenger_id = demo_passenger.id_number
      @expected_phone = demo_passenger.phone
      @expected_guest_name = demo_passenger.name  # 统一使用张三作为入住人
      
      # 查找去程航班（可以选择火车或航班）
      @outbound_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @outbound_date,
        data_version: 0
      ).order(price: :asc)
      
      @outbound_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      # 查找返程航班/火车
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @departure_city,
        flight_date: @return_date,
        data_version: 0
      ).order(price: :asc)
      
      @return_trains = Train.by_route(@destination_city, @departure_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      # 查找酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到符合条件的交通或酒店" if (@outbound_flights.empty? && @outbound_trains.empty?) || 
                                           (@return_flights.empty? && @return_trains.empty?) || 
                                           @available_hotels.empty?
      
      {
        task: "请预订#{@outbound_date.strftime('%Y年%m月%d日')}（第3天）从#{@departure_city}到#{@destination_city}的往返交通（#{@return_date.strftime('%Y年%m月%d日')}即第5天返回，去程后2天），并预订#{@destination_city}的酒店（住2晚）。请选择总价最低的组合（可以是航班或火车）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          outbound_date: @outbound_date,
          return_date: @return_date,
          check_in_date: @check_in_date,
          nights: 2,
          optimization: '总价最低'
        },
        hint: "需要计算【去程交通+返程交通+酒店2晚】的总价，选择最便宜的组合。可以混合选择航班和火车。"
      }
    end
    
    def verify
      add_assertion "创建了去程交通订单", weight: 10 do
        # 查找航班或火车订单
        @outbound_flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @outbound_train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @outbound_booking = @outbound_flight_booking || @outbound_train_booking
        @outbound_type = @outbound_flight_booking ? 'flight' : 'train'
        expect(@outbound_booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的去程交通订单"
      end
      
      return if @outbound_booking.nil?
      
      add_assertion "创建了返程交通订单", weight: 10 do
        @return_flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @destination_city, destination_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @return_train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @destination_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @return_booking = @return_flight_booking || @return_train_booking
        @return_type = @return_flight_booking ? 'flight' : 'train'
        expect(@return_booking).not_to be_nil, "未找到从#{@destination_city}到#{@departure_city}的返程交通订单"
      end
      
      return if @return_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 10 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "去程日期正确（#{@outbound_date}）", weight: 5 do
        if @outbound_type == 'flight'
          expect(@outbound_booking.flight.flight_date).to eq(@outbound_date),
            "去程航班日期错误。期望: #{@outbound_date}, 实际: #{@outbound_booking.flight.flight_date}"
        else
          outbound_train_date = @outbound_booking.train.departure_time.to_date
          expect(outbound_train_date).to eq(@outbound_date),
            "去程火车日期错误。期望: #{@outbound_date}, 实际: #{outbound_train_date}"
        end
      end
      
      add_assertion "返程日期正确（#{@return_date}，即第5天，去程后2天）", weight: 5 do
        if @return_type == 'flight'
          expect(@return_booking.flight.flight_date).to eq(@return_date),
            "返程航班日期错误。期望: #{@return_date}, 实际: #{@return_booking.flight.flight_date}"
        else
          return_train_date = @return_booking.train.departure_time.to_date
          expect(return_train_date).to eq(@return_date),
            "返程火车日期错误。期望: #{@return_date}, 实际: #{return_train_date}"
        end
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "去程和返程乘客信息正确（张三的姓名、身份证号、手机号）", weight: 5 do
        # 检查去程乘客信息
        expect(@outbound_booking.passenger_name).to eq(@expected_passenger_name),
          "去程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@outbound_booking.passenger_name}"
        expect(@outbound_booking.passenger_id_number).to eq(@expected_passenger_id),
          "去程身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@outbound_booking.passenger_id_number}"
        expect(@outbound_booking.contact_phone).to eq(@expected_phone),
          "去程联系电话错误。期望: #{@expected_phone}, 实际: #{@outbound_booking.contact_phone}"
        
        # 检查返程乘客信息
        expect(@return_booking.passenger_name).to eq(@expected_passenger_name),
          "返程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@return_booking.passenger_name}"
        expect(@return_booking.passenger_id_number).to eq(@expected_passenger_id),
          "返程身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@return_booking.passenger_id_number}"
        expect(@return_booking.contact_phone).to eq(@expected_phone),
          "返程联系电话错误。期望: #{@expected_phone}, 实际: #{@return_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三的姓名、手机号）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "选择了总价最低或接近最低的组合（实际总价≤理论最低价×1.2，允许20%偏差）", weight: 35 do
        outbound_price = @outbound_booking.total_price
        return_price = @return_booking.total_price
        hotel_price = @hotel_booking.total_price
        actual_total = outbound_price + return_price + hotel_price
        
        # 计算理论最低价格
        min_outbound = [@outbound_flights.first&.price || Float::INFINITY,
                        @outbound_trains.first&.price_second_class || Float::INFINITY].min
        min_return = [@return_flights.first&.price || Float::INFINITY,
                      @return_trains.first&.price_second_class || Float::INFINITY].min
        min_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
        min_hotel_price = min_hotel_room ? min_hotel_room.price * 2 : Float::INFINITY
        
        theoretical_min = min_outbound + min_return + min_hotel_price
        
        # 允许20%的偏差（考虑到可能的优化选择）
        acceptable_max = theoretical_min * 1.2
        
        expect(actual_total).to be <= acceptable_max,
          "总价未达到最优。实际总价: #{actual_total}元（去程#{outbound_price}+返程#{return_price}+酒店#{hotel_price}）, 理论最低: #{theoretical_min}元, 可接受上限: #{acceptable_max}元"
      end
      
      add_assertion "订单状态有效（去程、返程、酒店订单状态均为pending/paid/completed）", weight: 10 do
        expect(@outbound_booking.status).to be_in(['pending', 'paid', 'completed']),
          "去程订单状态异常。实际状态: #{@outbound_booking.status}"
        expect(@return_booking.status).to be_in(['pending', 'paid', 'completed']),
          "返程订单状态异常。实际状态: #{@return_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到最便宜的组合
      best_combo = nil
      best_price = Float::INFINITY
      
      # 遍历去程选择（航班或火车）
      outbound_options = []
      @outbound_flights.first(5).each { |f| outbound_options << { type: :flight, item: f, price: f.price } }
      @outbound_trains.first(5).each { |t| outbound_options << { type: :train, item: t, price: t.price_second_class } }
      
      # 遍历返程选择
      return_options = []
      @return_flights.first(5).each { |f| return_options << { type: :flight, item: f, price: f.price } }
      @return_trains.first(5).each { |t| return_options << { type: :train, item: t, price: t.price_second_class } }
      
      # 遍历酒店选择
      hotel_options = @available_hotels.first(5).map do |hotel|
        room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
        next unless room
        { hotel: hotel, room: room, price: room.price * 2 }  # 2晚
      end.compact
      
      # 找最便宜组合
      outbound_options.each do |outbound|
        return_options.each do |ret|
          hotel_options.each do |hotel_opt|
            total = outbound[:price] + ret[:price] + hotel_opt[:price]
            if total < best_price
              best_price = total
              best_combo = { outbound: outbound, return: ret, hotel: hotel_opt }
            end
          end
        end
      end
      
      raise "未找到符合条件的组合" if best_combo.nil?
      
      # 创建去程订单
      if best_combo[:outbound][:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:outbound][:item],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          total_price: best_combo[:outbound][:item].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:outbound][:item],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:outbound][:item].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建返程订单
      if best_combo[:return][:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:return][:item],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          total_price: best_combo[:return][:item].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:return][:item],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_passenger_id,
          contact_phone: @expected_phone,
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:return][:item].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel][:hotel],
        hotel_room_id: best_combo[:hotel][:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        payment_method: '花呗',
        total_price: best_combo[:hotel][:room].price * 2,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone,
        expected_guest_name: @expected_guest_name
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @outbound_date = Date.parse(data['outbound_date'])
      @return_date = Date.parse(data['return_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      @expected_guest_name = data['expected_guest_name']
      
      @outbound_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @outbound_date,
        data_version: 0
      ).order(price: :asc)
      
      @outbound_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @departure_city,
        flight_date: @return_date,
        data_version: 0
      ).order(price: :asc)
      
      @return_trains = Train.by_route(@destination_city, @departure_city)
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
