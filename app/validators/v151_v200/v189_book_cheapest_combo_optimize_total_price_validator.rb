# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例189: 给李四预订明天总价最低的北京到上海交通+酒店组合（整晚房，排除钟点房）
#
# 任务描述:
#   李四需要明天从北京到上海出差，要求预订总价最低的交通+酒店组合。
#   这是典型的价格优化场景，Agent需要比较所有航班和火车选项，
#   同时比较所有酒店选项（仅整晚房room_category='overnight'，排除钟点房），
#   找到交通+酒店总价最低的组合方案。
#
# 业务流程（6个关键步骤）：
#   1. 搜索北京→上海的所有交通选项（航班+火车，明天出发）
#   2. 比较所有交通工具的价格（航班price vs 火车price_second_class）
#   3. 选择最低价交通工具并预订（乘客李四）
#   4. 搜索上海的所有酒店（⚠️ 仅整晚房room_category='overnight'，排除钟点房）
#   5. 比较所有酒店的价格（整晚房最低价 * 入住晚数）
#   6. 选择最低价酒店并预订（凌晨到达可提前一天入住，其他航班当天或次日入住，住2晚）
#
# 复杂度分析（6个关键点）：
#   1. 需要跨类别比较价格：航班 vs 火车（不同模型，不同价格字段）
#   2. ⚠️ 需要过滤房型类别：只考虑整晚房（room_category='overnight'），排除钟点房
#      - Hotel.price 可能是钟点房价格（不准确）
#      - 必须使用 hotel.hotel_rooms.where(room_category: 'overnight').minimum(:price)
#   3. 需要计算酒店总价：房价 * 入住晚数（而不是单晚价格）
#   4. 需要全局优化：交通价格 + 酒店总价 的组合最小值
#   5. 需要验证总价在最低价的5%误差范围内（允许合理的非最优选择）
#   6. 需要确保交通和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索所有交通→比较价格→预订最低价交通→搜索所有酒店→过滤整晚房→比较价格→计算总价→预订最低价酒店
#
# 评分标准（8项，总计100分）：
#   - 创建了交通订单和酒店订单（双订单）（18分）
#   - 出发/到达城市正确（北京→上海）（13分）
#   - 酒店城市正确（上海）（8分）
#   - 日期合理（凌晨航班可提前一天入住，其他航班当天/次日入住）（13分）
#   - 总价最低或接近最低价（允许5%误差）（30分）
#   - 交通乘客信息正确（李四，含姓名）（3分）
#   - 交通联系电话正确（李四电话）（7分）
#   - 酒店入住人信息正确（李四，含姓名+电话）（8分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v189_book_cheapest_combo_optimize_total_price_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V189BookCheapestComboOptimizeTotalPriceValidator < BaseValidator
    self.validator_id = 'v189_book_cheapest_combo_optimize_total_price_validator'
    self.task_id = 'bba54fa4-35b4-4a29-942d-dd4d80abcd6d'
    self.title = '给李四预订明天总价最低的交通+酒店组合（整晚房，排除钟点房）'
    self.description = '帮李四预订明天从北京到上海的往返交通+酒店，总价要最低'
    self.timeout_seconds = 300
    
    def prepare
      # Step 1: 加载用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # Step 2: 设置查询条件
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @stay_nights = 2
      
      # Step 3: 查找所有交通选项（航班+火车，明天出发）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights.any? || @available_trains.any?).to be_truthy,
        "数据包缺失：未找到#{@departure_city}→#{@arrival_city}的交通工具（#{@travel_date}）"
      
      # 边界检查: 至少有一个类别包含多个选项，以便优化比较
      if @available_flights.size == 1 && @available_trains.empty?
        puts "警告: 仅有1个航班选项，无法进行价格优化比较"
      elsif @available_trains.size == 1 && @available_flights.empty?
        puts "警告: 仅有1个火车选项，无法进行价格优化比较"
      end
      
      # Step 4: 查找所有酒店（上海）
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺失：未找到#{@arrival_city}的酒店"
      expect(@available_hotels.size).to be >= 2,
        "数据包中酒店数量不足（仅#{@available_hotels.size}家），无法进行价格优化比较。至少需要2家酒店。"
      
      # Step 5: 计算最低组合价格（用于验证阶段的价格优化判断）
      @min_combo_price = calculate_min_combo_price
      
      # Step 6: 返回任务信息
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的往返交通+住宿#{@stay_nights}晚，要求总价最低",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        stay_nights: @stay_nights,
        optimization_target: '总价最低',
        hint: "系统中有#{@available_flights.size}个航班、#{@available_trains.size}个火车车次、#{@available_hotels.size}家酒店可选，请选择总价最低的组合"
      }
    end
    
    def verify
      # 断言1: 创建了交通订单和酒店订单（双订单存在性验证）
      add_assertion "创建了交通订单和酒店订单", weight: 18 do
        # 查询航班订单（按城市对筛选）
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        # 查询火车订单（按城市对筛选）
        @train_booking = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        has_transportation = @flight_booking.present? || @train_booking.present?
        expect(has_transportation).to be(true), 
          "未找到交通订单（#{@departure_city}→#{@arrival_city}）- 应预订航班或火车其中之一"
        
        # 查询酒店订单（按城市筛选）
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, 
          "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if (@flight_booking.nil? && @train_booking.nil?) || @hotel_booking.nil?
      
      # 断言2: 出发/到达城市正确（北京→上海）
      add_assertion "出发/到达城市正确（#{@departure_city}→#{@arrival_city}）", weight: 13 do
        if @flight_booking
          flight = @flight_booking.flight
          expect(flight.departure_city).to eq(@departure_city),
            "航班出发城市错误 - 期望: #{@departure_city}, 实际: #{flight.departure_city}"
          expect(flight.destination_city).to eq(@arrival_city),
            "航班到达城市错误 - 期望: #{@arrival_city}, 实际: #{flight.destination_city}"
        elsif @train_booking
          train = @train_booking.train
          expect(train.departure_city).to eq(@departure_city),
            "火车出发城市错误 - 期望: #{@departure_city}, 实际: #{train.departure_city}"
          expect(train.arrival_city).to eq(@arrival_city),
            "火车到达城市错误 - 期望: #{@arrival_city}, 实际: #{train.arrival_city}"
        end
      end
      
      # 断言3: 酒店城市正确（上海）
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 8 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city),
          "酒店城市错误 - 期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言4: 酒店入住日期正确（交通工具出发当天）
      add_assertion "酒店入住日期正确（交通工具出发当天）", weight: 13 do
        if @flight_booking
          departure_date = @flight_booking.flight.departure_time.to_date
          transport_type = "航班"
        elsif @train_booking
          departure_date = @train_booking.train.departure_time.to_date
          transport_type = "火车"
        end
        
        checkin_date = @hotel_booking.check_in_date
        
        # 酒店入住日期=交通工具出发当天（即使凌晨到达，也办理出发日的入住）
        expect(checkin_date).to eq(departure_date),
          "入住日期错误 - #{transport_type}出发: #{departure_date}, 酒店入住: #{checkin_date}（应为出发当天，即使凌晨到达也办理出发日入住）"
      end
      
      # 断言5: 总价最低或接近最低价（允许5%误差）
      add_assertion "总价最低或接近最低价（允许5%误差）", weight: 30 do
        transportation_price = @flight_booking ? @flight_booking.total_price.to_f : @train_booking.total_price.to_f
        hotel_price = @hotel_booking.total_price.to_f
        actual_total = transportation_price + hotel_price
        
        allowed_max = @min_combo_price.to_f * 1.05
        expect(actual_total).to be <= allowed_max,
          "总价未优化 - 期望: ≤#{allowed_max.round(2)}元（最低价#{@min_combo_price.to_f.round(2)}+5%误差）, 实际: #{actual_total.round(2)}元（交通#{transportation_price.round(2)}+酒店#{hotel_price.round(2)}）"
      end
      
      # 断言6: 交通乘客信息正确（李四）
      add_assertion "交通乘客信息正确（#{@expected_passenger_name}）", weight: 3 do
        if @flight_booking
          expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
            "航班乘客姓名错误 - 期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        elsif @train_booking
          expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
            "火车乘客姓名错误 - 期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        end
      end
      
      # 断言7: 交通联系电话正确（李四电话）
      add_assertion "交通联系电话正确（#{@expected_phone}）", weight: 7 do
        if @flight_booking
          expect(@flight_booking.contact_phone).to eq(@expected_phone),
            "航班联系电话错误 - 期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
        elsif @train_booking
          expect(@train_booking.contact_phone).to eq(@expected_phone),
            "火车联系电话错误 - 期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
        end
      end
      
      # 断言8: 酒店入住人信息正确（李四，含姓名+电话）
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误 - 期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误 - 期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    def simulate
      # Step 1: 加载用户和乘客
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      
      # Step 2: 找到最低价的交通工具（航班 vs 火车）
      cheapest_transport = find_cheapest_transportation
      
      # Step 3: 创建交通订单（航班或火车）
      if cheapest_transport[:type] == :flight
        flight = cheapest_transport[:data]
        Booking.create!(
          user: user,
          flight_id: flight.id,
          passenger_name: passenger.name,
          passenger_id_number: passenger.id_number,
          contact_phone: passenger.phone,
          total_price: flight.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
        departure_date = flight.departure_time.to_date
      else
        train = cheapest_transport[:data]
        TrainBooking.create!(
          user: user,
          train: train,
          passenger_name: passenger.name,
          passenger_id_number: passenger.id_number,
          seat_type: 'second_class',
          contact_phone: passenger.phone,
          total_price: train.price_second_class,
          accept_terms: true,
          data_version: @data_version
        )
        departure_date = train.departure_time.to_date
      end
      
      # Step 4: 找到最低价的酒店（只考虑整晚房，排除钟点房）
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      cheapest_hotel = @available_hotels.min_by do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end
      
      # Step 5: 创建酒店订单（入住日期=交通出发当天，住@stay_nights晚）
      room = cheapest_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: cheapest_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: cheapest_hotel.price,
          original_price: cheapest_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: departure_date,
        check_out_date: departure_date + @stay_nights.days,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price * @stay_nights,
        data_version: @data_version
      )
    end
    
    private
    
    def calculate_min_combo_price
      min_flight_price = @available_flights.any? ? @available_flights.min_by(&:price).price.to_f : Float::INFINITY
      min_train_price = @available_trains.any? ? @available_trains.min_by(&:price_second_class).price_second_class.to_f : Float::INFINITY
      min_transport = [min_flight_price, min_train_price].min
      
      # CRITICAL: 使用整晚房最低价，不是Hotel.price（可能是钟点房）
      min_hotel_overnight_price = @available_hotels.map do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end.min
      
      min_transport + (min_hotel_overnight_price * @stay_nights)
    end
    
    def find_cheapest_transportation
      min_flight_price = @available_flights.any? ? @available_flights.min_by(&:price).price.to_f : Float::INFINITY
      min_train_price = @available_trains.any? ? @available_trains.min_by(&:price_second_class).price_second_class.to_f : Float::INFINITY
      
      if min_flight_price <= min_train_price
        { type: :flight, data: @available_flights.min_by(&:price) }
      else
        { type: :train, data: @available_trains.min_by(&:price_second_class) }
      end
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        stay_nights: @stay_nights,
        min_combo_price: @min_combo_price,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      # Step 1: 恢复用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '李四'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      # Step 2: 恢复查询条件
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @stay_nights = data['stay_nights']
      @min_combo_price = data['min_combo_price']
      
      # Step 3: 重建可用交通和酒店数据
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
    end
  end
end
