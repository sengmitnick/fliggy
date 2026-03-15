# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例213: 张三需要预订明天早上到杭州的航班（12:00前到达）并当天入住酒店
#
# 任务描述:
#   张三明天需要早上到杭州办事，需要12:00前到达。Agent需要预订合适的早班航班，
#   并预订杭州酒店当天入住（提前入住场景）。
#
# 业务流程:
#   1. 张三向Agent提出需求：明天早上到杭州，12:00前到达，当天入住酒店
#   2. Agent查询明天到杭州的航班，筛选12:00前到达的航班
#   3. Agent选择合适的早班航班（优先最早到达）
#   4. Agent预订该航班，填写张三的乘客信息
#   5. Agent查询杭州的酒店
#   6. Agent选择合适的酒店（支持提前入住）
#   7. Agent预订酒店，入住日期为航班到达当天
#
# 复杂度分析:
#   1. 需要理解时间约束（12:00前到达）并筛选合适的早班航班
#   2. 需要计算航班到达时间对应的日期
#   3. 需要理解提前入住场景（早上到达，当天即入住）
#   4. 需要协调航班时间与酒店入住日期
#
# 评分标准:
#   - 创建了航班和酒店订单 (15分)
#   - 航班到达城市正确（杭州） (10分)
#   - 航班出发日期正确（明天） (10分)
#   - 航班到达时间≤12:00（满足早到要求） (20分)
#   - 酒店位于杭州 (10分)
#   - 酒店入住日期为到达当天（提前入住逻辑） (20分)
#   - 乘客/入住人信息正确（张三） (10分)
#   - 订单状态有效 (5分)
module V201V250
  class V213BookEarlyCheckInHotelBeforeNoonValidator < BaseValidator
    self.validator_id = 'v213_book_early_check_in_hotel_before_noon_validator'
    self.task_id = '2fd354f7-3f3f-4f6f-ff6f-7f9a0b1c2d3f'
    self.title = '张三需要预订明天早上到杭州的航班（12:00前到达）并当天入住酒店'
    self.description = '张三需要预订明天早上到杭州的航班（12:00前到达）并当天入住酒店'
    self.timeout_seconds = 300
    
    def prepare
      @destination_city = '杭州'
      @flight_date = Date.current + 1.day
      @max_arrival_hour = 12
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
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
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。张三需要预订明天早上到杭州的航班（12:00前到达）并当天入住酒店",
        description: "张三需要预订明天早上到杭州的航班（12:00前到达）并当天入住酒店",
        scenario: "张三明天需要到杭州办事，要求12:00前到达，航班到达后直接入住酒店",
        requirements: {
          destination_city: @destination_city,
          flight_date: @flight_date.strftime('%Y-%m-%d'),
          max_arrival_time: "≤12:00",
          check_in_date: @check_in_date.strftime('%Y-%m-%d'),
          passenger: '张三',
          purpose: '早班航班提前入住'
        },
        available_flights_sample: {
          count: @available_flights.size,
          example: @available_flights.first ? "#{@available_flights.first.flight_number}（#{@available_flights.first.departure_time.strftime('%H:%M')}起飞，#{@available_flights.first.arrival_time.strftime('%H:%M')}到达）" : nil
        },
        available_hotels_sample: {
          count: @available_hotels.size,
          example: @available_hotels.first ? "#{@available_hotels.first.name}（#{@available_hotels.first.city}）" : nil
        }
      }
    end
    
    def verify
      add_assertion "创建了航班和酒店订单", weight: 15 do
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
      
      add_assertion "航班出发日期正确（明天#{@flight_date}）", weight: 10 do
        expect(@flight_booking.flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（明天）, 实际: #{@flight_booking.flight.flight_date}"
      end
      
      add_assertion "航班到达时间≤12:00（满足早到要求）", weight: 20 do
        hour = @flight_booking.flight.arrival_time.hour
        expect(hour).to be < @max_arrival_hour,
          "到达时间过晚。期望: <#{@max_arrival_hour}:00, 实际: #{@flight_booking.flight.arrival_time.strftime('%H:%M')}"
      end
      
      add_assertion "酒店位于#{@destination_city}", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@destination_city),
          "酒店城市错误。期望: #{@destination_city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "酒店入住日期为到达当天（提前入住逻辑）", weight: 20 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        expect(@hotel_booking.check_in_date).to eq(arrival_date),
          "入住日期错误。期望: #{arrival_date}（到达日期）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "乘客/入住人信息正确（张三）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_guest_name),
          "航班乘客姓名错误。期望: #{@expected_guest_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
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
        passenger_name: @expected_guest_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
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
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
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
        check_in_date: @check_in_date.to_s,
        expected_guest_name: @expected_guest_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @max_arrival_hour = data['max_arrival_hour']
      @check_in_date = Date.parse(data['check_in_date'])
      @expected_guest_name = data['expected_guest_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
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
