# frozen_string_literal: true

require_relative '../base_validator'

# V220: 预订家庭出行套餐（2大1小，总预算≤5000元）
#
# 任务描述:
#   用户需要预订2大1小出行套餐，总预算≤5000元
#
# 评分标准:
#   - 创建了航班订单（至少包含3张票） (30分) - 核心评分项
#   - 创建了酒店订单 (15分)
#   - 航班日期正确（3天后） (10分)
#   - 酒店入住日期正确 (10分)
#   - 总价格≤5000元 (15分) - 核心评分项
#   - 乘客/入住人信息正确（2大1小） (10分)
#   - 订单状态有效 (10分)
module V201V250
  class V220BookFamilyTripBudget5000Validator < BaseValidator
    self.validator_id = 'v220_book_family_trip_budget_5000_validator'
    self.task_id = '7fc798fb-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '帮张三订3天后从北京到三亚的家庭出行套餐（2大人1儿童）+酒店2晚，总预算不超过5000元'
    self.description = '帮张三订3天后从北京到三亚的家庭出行套餐（2大人1儿童）+酒店2晚，总预算不超过5000元'
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
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_adult_name = @passenger.name
      @expected_child_name = '小明'  # 儿童名字
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
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
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的家庭出行套餐（2大人1儿童），并预订#{@arrival_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          passengers: '2大1小',
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要为2大1小预订机票和酒店，确保总价不超过#{@max_budget}元。"
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
      
      # 断言6: 乘客/入住人信息正确（2大1小） (10分)
      add_assertion "乘客/入住人信息正确（2大1小）", weight: 10 do
        passenger_names = @flight_bookings.map(&:passenger_name)
        adult_count = passenger_names.count(@expected_adult_name)
        child_count = passenger_names.count(@expected_child_name)
        
        expect(adult_count).to be >= 1, "成人乘客数量不足。期望至少1个#{@expected_adult_name}, 实际: #{adult_count}个"
        expect(child_count).to be >= 1, "儿童乘客数量不足。期望至少1个#{@expected_child_name}, 实际: #{child_count}个"
        expect(@hotel_booking.guest_name).to eq(@expected_adult_name),
          "酒店入住人姓名错误。期望: #{@expected_adult_name}, 实际: #{@hotel_booking.guest_name}"
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
      
      # 创建航班订单（为2大1小各创建一个订单）
      3.times do |idx|
        Booking.create!(
          user: user,
          flight: best_combo[:flight],
          passenger_name: idx == 2 ? @expected_child_name : @expected_adult_name,
          passenger_id_number: @expected_id_number,
          contact_phone: @expected_phone,
          total_price: best_combo[:flight].price,
          accept_terms: true,
          status: 'paid',
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
        guest_name: @expected_adult_name,
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
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        adults: @adults,
        children: @children,
        max_budget: @max_budget,
        expected_adult_name: @expected_adult_name,
        expected_child_name: @expected_child_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
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
      @expected_adult_name = data['expected_adult_name']
      @expected_child_name = data['expected_child_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
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
