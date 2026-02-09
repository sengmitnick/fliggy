# frozen_string_literal: true

require_relative '../base_validator'

# V212: 预订深夜航班+凌晨入住酒店
#
# 任务描述:
#   用户需要预订明天深夜23:00后航班到上海+凌晨后入住酒店（24小时前台）
#
# 评分标准:
#   - 创建了航班和酒店订单 (20%)
#   - 航班到达城市正确（上海） (10%)
#   - 航班起飞时间≥23:00 (15%)
#   - 酒店位于上海 (10%)
#   - 酒店入住日期为到达当天 (25%)
#   - 订单状态有效 (20%)
module V201V250
  class V212BookHotelCheckInAfterMidnightValidator < BaseValidator
    self.validator_id = 'v212_book_hotel_check_in_after_midnight_validator'
    self.task_id = '1fc243f6-2f2f-4f5f-ff5f-6f8a9b0c1d2f'
    self.title = '预订明天深夜航班+凌晨入住酒店'
    self.description = '用户需要预订明天深夜23:00后航班到上海+凌晨后入住酒店（24小时前台）'
    self.timeout_seconds = 300
    
    def prepare
      @destination_city = '上海'
      @flight_date = Date.current + 1.day
      @min_departure_hour = 23
      
      # 查找深夜航班（23:00后）
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= @min_departure_hour }
      
      # 查找上海的酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
      
      raise "未找到符合条件的深夜航班" if @available_flights.empty?
      raise "未找到上海的酒店" if @available_hotels.empty?
      
      # 入住日期应该是到达日期（可能是次日）
      sample_flight = @available_flights.first
      @check_in_date = sample_flight.arrival_time.to_date
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）深夜23:00后到#{@destination_city}的航班，并预订#{@destination_city}24小时前台酒店，凌晨后可入住。",
        requirements: {
          destination_city: @destination_city,
          flight_date: @flight_date,
          min_departure_hour: "≥23:00",
          check_in_date: @check_in_date,
          purpose: '深夜航班凌晨入住'
        },
        hint: "选择23:00后的航班，然后预订酒店入住日期为到达日期（可能是次日）。"
      }
    end
    
    def verify
      add_assertion "创建了航班和酒店订单", weight: 20 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到到#{@destination_city}的航班订单"
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @flight_booking.nil? || @hotel_booking.nil?
      
      add_assertion "航班到达城市正确（#{@destination_city}）", weight: 10 do
        expect(@flight_booking.flight.destination_city).to eq(@destination_city),
          "到达城市错误。期望: #{@destination_city}, 实际: #{@flight_booking.flight.destination_city}"
      end
      
      add_assertion "航班起飞时间≥23:00", weight: 15 do
        hour = @flight_booking.flight.departure_time.hour
        expect(hour).to be >= @min_departure_hour,
          "起飞时间过早。期望: ≥#{@min_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "酒店位于#{@destination_city}", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@destination_city),
          "酒店城市错误。期望: #{@destination_city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "酒店入住日期为到达当天", weight: 25 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        expect(@hotel_booking.check_in_date).to eq(arrival_date),
          "入住日期错误。期望: #{arrival_date}（到达日期）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最便宜的深夜航班
      flight = @available_flights.min_by(&:price)
      arrival_date = flight.arrival_time.to_date
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 选择价格合理的酒店（过滤nil价格）
      valid_hotels = @available_hotels.select { |h| h.price.present? }
      raise "未找到有效价格的酒店" if valid_hotels.empty?
      
      hotel = valid_hotels.min_by(&:price)
      room = hotel.hotel_rooms.where(data_version: 0).where.not(price: nil).order(price: :asc).first
      raise "未找到酒店房间" unless room
      
      # 创建酒店订单（入住日期为到达日期）
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: room.price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        min_departure_hour: @min_departure_hour,
        check_in_date: @check_in_date.to_s
      }
    end
    
    def restore_from_state(data)
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @min_departure_hour = data['min_departure_hour']
      @check_in_date = Date.parse(data['check_in_date'])
      
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= @min_departure_hour }
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
    end
  end
end
