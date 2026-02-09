# frozen_string_literal: true

require_relative '../base_validator'

# V219: 预订往返航班+酒店3晚（总预算≤2000元）
#
# 任务描述:
#   用户需要预订往返航班+酒店3晚，总预算≤2000元
#
# 评分标准:
#   - 创建了往返航班订单（2个） (20%)
#   - 创建了酒店订单 (15%)
#   - 酒店住3晚 (10%)
#   - 总价格≤2000元 (35%)
#   - 订单状态有效 (20%)
module V201V250
  class V219BookRoundTripBudget2000Validator < BaseValidator
    self.validator_id = 'v219_book_round_trip_budget_2000_validator'
    self.task_id = '6fb687fa-7f7f-7f9f-9f0f-8f1a2b3c4d5e'
    self.title = '预订往返航班+酒店3晚（总预算≤2000元）（2个航班）'
    self.description = '用户需要预订往返航班+酒店3晚，总预算≤2000元'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '深圳'
      @destination_city = '上海'
      @nights = 3
      @max_budget = 2000
      
      # 查找往返航班（不限定日期）
      @outbound_flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @origin_city,
        data_version: 0
      ).order(price: :asc)
      
      # 查找酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到往返航班或酒店" if @outbound_flights.empty? || @return_flights.empty? || @available_hotels.empty?
      
      # 使用实际存在的航班日期
      @outbound_date = @outbound_flights.first.flight_date
      @return_date = (@return_flights.where('flight_date > ?', @outbound_date).first || @return_flights.first).flight_date
      @check_in_date = @outbound_date
      @check_out_date = @check_in_date + @nights.days
      
      {
        task: "请预订#{@outbound_date.strftime('%Y年%m月%d日')}（后天）从#{@origin_city}到#{@destination_city}的往返航班（#{@return_date.strftime('%m月%d日')}返回），并预订#{@destination_city}酒店#{@nights}晚。总预算不超过#{@max_budget}元。",
        requirements: {
          origin_city: @origin_city,
          destination_city: @destination_city,
          outbound_date: @outbound_date,
          return_date: @return_date,
          nights: @nights,
          max_budget: @max_budget
        },
        hint: "需要综合考虑往返机票和酒店3晚的价格，确保总价不超过#{@max_budget}元。"
      }
    end
    
    def verify
      add_assertion "创建了往返航班订单（2个）", weight: 20 do
        outbound_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @origin_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        return_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @destination_city, destination_city: @origin_city })
          .where(data_version: @data_version)
          .to_a
        
        @outbound_booking = outbound_bookings.first
        @return_booking = return_bookings.first
        
        expect(@outbound_booking).not_to be_nil, "未找到去程航班订单"
        expect(@return_booking).not_to be_nil, "未找到返程航班订单"
      end
      
      return if @outbound_booking.nil? || @return_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店住#{@nights}晚", weight: 10 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 35 do
        outbound_price = @outbound_booking.total_price
        return_price = @return_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = outbound_price + return_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。去程: #{outbound_price}元, 返程: #{return_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@outbound_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@return_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳组合
      best_combo = nil
      best_value = 0
      
      @outbound_flights.first(5).each do |outbound|
        @return_flights.first(5).each do |return_flight|
          @available_hotels.first(5).each do |hotel|
            room = hotel.hotel_rooms.where(data_version: 0).first
            next unless room
            
            total = outbound.price + return_flight.price + (room.price * @nights)
            next if total > @max_budget
            
            value_score = @max_budget - total
            if best_combo.nil? || value_score > best_value
              best_combo = { outbound: outbound, return: return_flight, hotel: hotel, room: room }
              best_value = value_score
            end
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建去程航班订单
      Booking.create!(
        user: user,
        flight: best_combo[:outbound],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_combo[:outbound].price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建返程航班订单
      Booking.create!(
        user: user,
        flight: best_combo[:return],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_combo[:return].price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
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
        origin_city: @origin_city,
        destination_city: @destination_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        max_budget: @max_budget
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
      
      @outbound_flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @origin_city,
        data_version: 0
      ).order(price: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
