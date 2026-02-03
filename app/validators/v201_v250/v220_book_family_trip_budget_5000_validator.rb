# frozen_string_literal: true

require_relative '../base_validator'

# V220: 预订家庭出行套餐（2大1小，总预算≤5000元）
#
# 任务描述:
#   用户需要预订2大1小出行套餐，总预算≤5000元
#
# 评分标准:
#   - 创建了航班订单（至少包含3张票） (25%)
#   - 创建了酒店订单 (15%)
#   - 总价格≤5000元 (40%)
#   - 订单状态有效 (20%)
module V201V250
  class V220BookFamilyTripBudget5000Validator < BaseValidator
    self.validator_id = 'v220_book_family_trip_budget_5000_validator'
    self.task_id = '7fc798fb-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '预订家庭出行套餐（2大1小≤5000元）'
    self.description = '用户需要预订2大1小出行套餐，总预算≤5000元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '三亚'
      @flight_date = Date.today + 3.days
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 2.days
      @nights = 2
      @adults = 2
      @children = 1
      @max_budget = 5000
      
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
      add_assertion "创建了航班订单", weight: 25 do
        @flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .to_a
        
        expect(@flight_bookings).not_to be_empty, "未找到航班订单"
      end
      
      return if @flight_bookings.empty?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "总价格≤#{@max_budget}元", weight: 40 do
        flight_total = @flight_bookings.sum(&:total_price)
        hotel_price = @hotel_booking.total_price
        total_price = flight_total + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。航班: #{flight_total}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
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
      [@adults, @children].flatten.each_with_index do |_, idx|
        Booking.create!(
          user: user,
          flight: best_combo[:flight],
          passenger_name: idx == 2 ? '小明' : user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: best_combo[:flight].price,
          accept_terms: true,
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
        guest_name: user.name,
        guest_phone: '13800138000',
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
        max_budget: @max_budget
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
