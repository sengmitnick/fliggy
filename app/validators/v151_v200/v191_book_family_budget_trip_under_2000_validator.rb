# frozen_string_literal: true

require_relative '../base_validator'

module V151V200
  # V191: 为张三、王芳、小明（2大1小）预订后天从北京到上海的火车+上海酒店（总预算2000元内）
  #
  # 任务描述：
  #   为张三、王芳、小明（2大1小）预订后天从北京到上海的火车+上海酒店
  #
  # 核心要求：
  #   - 家庭成员：2个成人（张三、王芳）+ 1个儿童（小明）
  #   - 出发日期：后天（Date.current + 2.days）
  #   - 路线：北京 → 上海
  #   - 预算限制：总价 ≤ 2000元
  #   - 儿童票价：成人票价的50%
  #   - 酒店入住日期：火车出发当天（departure_date，不是arrival_date）
  #
  # 业务流程：
  #   1. 查询后天北京→上海的火车（departure_city + arrival_city + travel_date）
  #   2. 筛选符合预算的火车和酒店组合（火车票*2.5 + 酒店 ≤ 2000）
  #   3. 选择最便宜的火车（price_second_class最小）
  #   4. 为3位乘客创建火车票订单（使用booking_group_id关联）：
  #      - 张三（成人票，全价）
  #      - 王芳（成人票，全价）
  #      - 小明（儿童票，半价）
  #   5. 选择最便宜的酒店房间（price最小）
  #   6. 创建酒店订单：
  #      - 入住日期：火车出发当天（departure_date）
  #      - 退房日期：入住日期+1天
  #
  # 复杂度分析：
  #   - 数据量：火车（10条），酒店（5家，各3个房型）
  #   - 计算复杂度：O(10 × 15) = 150次价格组合计算
  #   - 关键优化：使用二次筛选（先按单项价格过滤，再计算组合）
  #
  # 验证要点：
  #   - 火车票总价 = 成人票×2 + 儿童票×1 = price_second_class × 2.5
  #   - 酒店入住日期 = departure_date（不是arrival_date）
  #   - 总价 ≤ 2000元
  #   - 3个火车票订单通过booking_group_id关联
  class V191BookFamilyBudgetTripUnder2000Validator < BaseValidator
    self.validator_id = 'v191_book_family_budget_trip_under_2000_validator'
    self.task_id = 'f8a3e2d1-4b5c-6789-abcd-ef0123456789'
    self.title = '为张三、王芳、小明（2大1小）预订后天从北京到上海的火车+上海酒店（总预算2000元内）'
    self.description = '帮张三、王芳、小明（2大1小）预订后天从北京到上海的火车+酒店，要求总预算控制在2000元内，儿童票半价'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 2.days
      @max_budget = 2000
      @adult_count = 2
      @child_count = 1
      @expected_passengers = ['张三', '王芳', '小明']
      
      # Step 1: 查询后天北京→上海的火车（使用 .by_date 作用域）
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date).to_a
      
      if @available_trains.empty?
        return {
          status: 'error',
          message: "未找到#{@travel_date}从#{@departure_city}到#{@arrival_city}的火车"
        }
      end
      
      # Step 2: 查询上海的酒店（price > 0）
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).where('price > 0').order(price: :asc).limit(10).to_a
      
      if @available_hotels.empty?
        return {
          status: 'error',
          message: "未找到#{@arrival_city}的酒店"
        }
      end
      
      # Step 3: 筛选符合预算的组合（火车票*2.5 + 酒店房间 ≤ 2000）
      valid_combinations = []
      @available_trains.each do |train|
        train_total = train.price_second_class.to_f * 2.5  # 2个成人票 + 1个儿童票（半价）
        
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total_price = train_total + room.price.to_f
          if total_price <= @max_budget
            valid_combinations << {
              train: train,
              hotel: hotel,
              room: room,
              total_price: total_price
            }
          end
        end
      end
      
      if valid_combinations.empty?
        return {
          status: 'error',
          message: "未找到预算#{@max_budget}元内的火车+酒店组合"
        }
      end
      
      # Step 4: 返回准备结果
      {
        status: 'success',
        message: "找到#{valid_combinations.size}种符合预算的组合（火车#{@available_trains.size}条，酒店#{@available_hotels.size}家）",
        travel_date: @travel_date,
        route: "#{@departure_city} → #{@arrival_city}",
        budget: @max_budget,
        family: "2大1小（#{@expected_passengers.join('、')}）",
        valid_combinations_count: valid_combinations.size
      }
    end
  
    def simulate
      # Step 1: 加载用户和乘客
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # Step 2: 选择最便宜的火车
      cheapest_train = @available_trains.min_by(&:price_second_class)
      
      # Step 3: 创建火车票（为每个乘客创建独立订单，使用booking_group_id关联）
      booking_group_id = SecureRandom.uuid
      
      train_bookings = [
        { passenger: zhangsan, price: cheapest_train.price_second_class },
        { passenger: wangfang, price: cheapest_train.price_second_class },
        { passenger: xiaoming, price: cheapest_train.price_second_class * 0.5 }
      ].map do |booking_data|
        TrainBooking.create!(
          user: user,
          train: cheapest_train,
          booking_group_id: booking_group_id,  # 关联同组订单
          passenger_name: booking_data[:passenger].name,
          passenger_id_number: booking_data[:passenger].id_number,
          passenger_phone: booking_data[:passenger].phone,
          contact_phone: booking_data[:passenger].phone,
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: booking_data[:price],
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # Step 4: 创建酒店订单（入住日期=火车出发当天，住1晚）
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      departure_date = cheapest_train.departure_time.to_date
      hotel_booking = HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: departure_date,
        check_out_date: departure_date + 1.day,
        guest_name: user.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
      
      {
        status: 'success',
        message: "已创建3个火车票订单（group: #{booking_group_id}）和1个酒店订单（#{hotel_booking.id}）",
        train_bookings: train_bookings.map(&:id),
        hotel_booking_id: hotel_booking.id
      }
    end
  
    def verify
      # 断言1: 创建了3个火车票订单（2大1小）
      add_assertion "创建了3个火车票订单（张三、王芳、小明）", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到火车票订单"
        
        # 筛选后天的订单（使用 departure_time.to_date）
        @train_bookings = all_bookings.select { |b| b.train.departure_time.to_date == @travel_date }
        
        if @train_bookings.empty?
          actual_dates = all_bookings.map { |b| b.train.departure_time.to_date }.uniq.join(', ')
          raise "火车票日期错误。期望: #{@travel_date}（后天）, 实际: #{actual_dates}"
        end
        
        expect(@train_bookings.size).to eq(3), 
          "订单数量错误。期望3个订单（2大1小），实际找到#{@train_bookings.size}个订单"
      end
      
      return if @train_bookings.nil? || @train_bookings.empty?
      
      # 断言2: 出发城市和到达城市正确（北京 → 上海）
      add_assertion "路线正确（#{@departure_city} → #{@arrival_city}）", weight: 15 do
        @train_bookings.each do |booking|
          train = booking.train
          expect(train.departure_city).to eq(@departure_city),
            "出发城市错误。订单ID: #{booking.id}, 期望: #{@departure_city}, 实际: #{train.departure_city}"
          expect(train.arrival_city).to eq(@arrival_city),
            "到达城市错误。订单ID: #{booking.id}, 期望: #{@arrival_city}, 实际: #{train.arrival_city}"
        end
      end
      
      # 断言3: 乘客名字正确（张三、王芳、小明）
      add_assertion "乘客名字正确（#{@expected_passengers.join('、')}）", weight: 10 do
        actual_names = @train_bookings.map(&:passenger_name).sort
        expect(actual_names).to match_array(@expected_passengers.sort),
          "乘客名字错误。期望: #{@expected_passengers.sort.join('、')}, 实际: #{actual_names.join('、')}"
      end
      
      # 断言4: 出发日期正确（后天）
      add_assertion "出发日期正确（后天: #{@travel_date}）", weight: 10 do
        @train_bookings.each do |booking|
          actual_date = booking.train.departure_time.to_date
          expect(actual_date).to eq(@travel_date),
            "订单ID: #{booking.id}, 出发日期错误。期望: #{@travel_date}（后天）, 实际: #{actual_date}"
        end
      end
      
      # 断言5: 座位类型正确（二等座）
      add_assertion "座位类型正确（二等座）", weight: 5 do
        @train_bookings.each do |booking|
          expect(booking.seat_type).to eq('second_class'),
            "订单ID: #{booking.id}, 座位类型错误。期望: second_class, 实际: #{booking.seat_type}"
        end
      end
      
      # 断言6: 儿童票价格正确（成人票的50%）
      add_assertion "儿童票价格正确（成人票的50%）", weight: 10 do
        # 找到小明的订单
        xiaoming_booking = @train_bookings.find { |b| b.passenger_name == '小明' }
        expect(xiaoming_booking).not_to be_nil, "未找到小明的订单"
        
        # 找到成人订单（张三或王芳）
        adult_booking = @train_bookings.find { |b| ['张三', '王芳'].include?(b.passenger_name) }
        expect(adult_booking).not_to be_nil, "未找到成人订单"
        
        expected_child_price = adult_booking.total_price.to_f * 0.5
        actual_child_price = xiaoming_booking.total_price.to_f
        
        expect(actual_child_price).to be_within(0.01).of(expected_child_price),
          "儿童票价格错误。期望: #{expected_child_price}（成人票#{adult_booking.total_price}的50%）, 实际: #{actual_child_price}"
      end
      
      # 断言7: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@hotel_bookings).not_to be_empty, "未找到酒店订单"
        @hotel_booking = @hotel_bookings.first
      end
      
      return if @hotel_bookings.nil? || @hotel_bookings.empty?
      
      # 断言8: 酒店入住日期正确（火车出发当天）
      add_assertion "酒店入住日期正确（火车出发当天: #{@travel_date}）", weight: 10 do
        actual_check_in = @hotel_booking.check_in_date
        expect(actual_check_in).to eq(@travel_date),
          "入住日期错误。期望: #{@travel_date}（火车出发当天）, 实际: #{actual_check_in}"
      end
      
      # 断言9: 总预算控制在2000元内
      add_assertion "总预算控制在#{@max_budget}元内", weight: 5 do
        train_total = @train_bookings.sum { |b| b.total_price.to_f }
        hotel_total = @hotel_bookings.sum { |b| b.total_price.to_f }
        actual_total = train_total + hotel_total
        
        expect(actual_total).to be <= @max_budget,
          "总价超出预算。期望: ≤#{@max_budget}元, 实际: #{actual_total}元（火车#{train_total}元 + 酒店#{hotel_total}元）"
      end
    end
  
    private
  
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_budget: @max_budget,
        adult_count: @adult_count,
        child_count: @child_count,
        expected_passengers: @expected_passengers
      }
    end
  
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_budget = data['max_budget']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @expected_passengers = data['expected_passengers'] || ['张三', '王芳', '小明']
    end
  end
end
