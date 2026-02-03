# frozen_string_literal: true

require_relative '../base_validator'

# V213: 预订航班+酒店早入住（12:00前）
#
# 任务描述:
#   用户需要预订明天早上航班到杭州+酒店12:00前提前入住
#
# 评分标准:
#   - 创建了航班和酒店订单 (20%)
#   - 航班到达城市正确（杭州） (10%)
#   - 航班到达时间≤12:00 (15%)
#   - 酒店位于杭州 (10%)
#   - 酒店入住日期为到达当天 (25%)
#   - 订单状态有效 (20%)
module V201V250
  class V213BookEarlyCheckInHotelBeforeNoonValidator < BaseValidator
    self.validator_id = 'v213_book_early_check_in_hotel_before_noon_validator'
    self.task_id = '2fd354f7-3f3f-4f6f-ff6f-7f9a0b1c2d3f'
    self.title = '预订航班+酒店早入住（12:00前）'
    self.description = '用户需要预订明天早上航班到杭州+酒店12:00前提前入住'
    self.timeout_seconds = 300
    
    def prepare
      @destination_city = '杭州'
      @flight_date = Date.today + 1.day
      @max_arrival_hour = 12
      
      # 查找早上到达的航班（12:00前）
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.arrival_time.hour < @max_arrival_hour }
      
      # 查找杭州的酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
      
      raise "未找到12:00前到达的航班" if @available_flights.empty?
      raise "未找到杭州的酒店" if @available_hotels.empty?
      
      @check_in_date = @flight_date
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）早上到#{@destination_city}的航班（12:00前到达），并预订#{@destination_city}酒店当天入住，支持提前入住。",
        requirements: {
          destination_city: @destination_city,
          flight_date: @flight_date,
          max_arrival_hour: "≤12:00到达",
          check_in_date: @check_in_date,
          purpose: '早到提前入住'
        },
        hint: "选择12:00前到达的航班，然后预订酒店入住日期为到达当天。"
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
      
      add_assertion "航班到达时间≤12:00", weight: 15 do
        hour = @flight_booking.flight.arrival_time.hour
        expect(hour).to be < @max_arrival_hour,
          "到达时间过晚。期望: <#{@max_arrival_hour}:00, 实际: #{@flight_booking.flight.arrival_time.strftime('%H:%M')}"
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
      
      # 选择最早到达的航班
      flight = @available_flights.min_by { |f| f.arrival_time }
      arrival_date = flight.arrival_time.to_date
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 选择价格合理的酒店
      hotel = @available_hotels.min_by(&:price)
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      # 创建酒店订单（入住日期为到达日期）
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: hotel.price,
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
        max_arrival_hour: @max_arrival_hour,
        check_in_date: @check_in_date.to_s
      }
    end
    
    def restore_from_state(data)
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @max_arrival_hour = data['max_arrival_hour']
      @check_in_date = Date.parse(data['check_in_date'])
      
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.arrival_time.hour < @max_arrival_hour }
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
    end
  end
end
