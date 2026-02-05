# frozen_string_literal: true

require_relative '../base_validator'

# V217: 预订航班+酒店（总预算≤1500元）
#
# 任务描述:
#   用户需要预订航班+酒店，总预算≤1500元
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 总价格≤1500元 (40%)
#   - 订单状态有效 (20%)
module V201V250
  class V217BookFlightAndHotelBudget1500Validator < BaseValidator
    self.validator_id = 'v217_book_flight_and_hotel_budget_1500_validator'
    self.task_id = 'a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d'
    self.title = '预订航班+酒店（总预算≤1500元）'
    self.description = '用户需要预订航班+酒店，总预算≤1500元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @arrival_city = '北京'
      @flight_date = Date.current + 2.days
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 1.day
      @max_budget = 1500
      
      # 查找可用航班
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(price: :asc)
      
      # 查找可用酒店
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到符合条件的航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      # 检查是否有组合满足预算
      cheapest_combo = @available_flights.first.price + @available_hotels.first.price
      raise "最便宜的组合(#{cheapest_combo}元)超出预算#{@max_budget}元" if cheapest_combo > @max_budget
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班，并预订#{@arrival_city}的酒店（当晚入住1晚）。总预算不超过#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          hotel_city: @arrival_city,
          check_in_date: @check_in_date,
          nights: 1,
          max_budget: @max_budget
        },
        hint: "需要综合考虑航班和酒店的价格，确保总价不超过#{@max_budget}元。优先选择性价比高的组合。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_flight_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @flight_booking = all_flight_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@arrival_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "总价格≤#{@max_budget}元", weight: 40 do
        flight_price = @flight_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = flight_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。航班: #{flight_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "航班订单状态异常。实际状态: #{@flight_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳组合
      best_combo = nil
      best_value = 0  # 性价比分数（可以基于价格和评分计算）
      
      @available_flights.each do |flight|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total = flight.price + room.price
          next if total > @max_budget
          
          # 计算性价比（剩余预算越多越好）
          value_score = @max_budget - total
          
          if best_combo.nil? || value_score > best_value
            best_combo = { flight: flight, hotel: hotel, room: room }
            best_value = value_score
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight: best_combo[:flight],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_combo[:flight].price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room_id: best_combo[:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
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
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
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
