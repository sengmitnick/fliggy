# frozen_string_literal: true

require_relative '../base_validator'

# V236: 预订多人出行（订多张票/多个房间）
#
# 任务描述:
#   用户需要为多人预订（如家庭出行，订2张机票+2个房间）
#
# 评分标准:
#   - 创建了交通订单 (20%)
#   - 乘客数量正确（≥2人） (25%)
#   - 创建了酒店订单 (20%)
#   - 房间数量正确（≥2间） (25%)
#   - 订单状态有效 (10%)
module V201V250
  class V236BookMultiplePeopleValidator < BaseValidator
    self.validator_id = 'v236_book_multiple_people_validator'
    self.task_id = '2ff2e3ff-3f3f-3f5f-5f6f-4f7a8b9c0d1f'
    self.title = '预订多人出行（多张票+多个房间）'
    self.description = '用户需要为多人预订（如家庭出行，订2张机票+2个房间）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @travel_date = Date.current + 5.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 3.days
      @passenger_count = 4  # 4人家庭
      @room_count = 2  # 2个房间
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
      
      raise "未找到航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      {
        task: "请为#{@passenger_count}人家庭预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的航班（#{@passenger_count}张票）和酒店（#{@room_count}个房间，住3晚）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          passenger_count: "#{@passenger_count}人",
          room_count: "#{@room_count}个房间",
          nights: 3,
          purpose: '家庭出行'
        },
        hint: "需要订#{@passenger_count}张机票和#{@room_count}个房间。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_bookings = all_bookings
        expect(@flight_bookings).not_to be_empty, "未找到航班订单"
      end
      
      return if @flight_bookings.empty?
      
      add_assertion "乘客数量正确（≥#{@passenger_count}人）", weight: 25 do
        # 可能是多个订单或单个订单包含多人
        total_passengers = @flight_bookings.sum do |booking|
          booking.passenger_name.split(',').size  # 假设多人用逗号分隔，或单个订单
        end
        
        # 也可能是分开的订单
        if total_passengers < @passenger_count
          total_passengers = @flight_bookings.size
        end
        
        expect(total_passengers).to be >= @passenger_count,
          "乘客数量不足。要求: ≥#{@passenger_count}人, 实际: #{total_passengers}人"
      end
      
      add_assertion "创建了酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @hotel_bookings = all_hotel_bookings
        expect(@hotel_bookings).not_to be_empty, "未找到酒店订单"
      end
      
      return if @hotel_bookings.empty?
      
      add_assertion "房间数量正确（≥#{@room_count}间）", weight: 25 do
        total_rooms = @hotel_bookings.sum(&:room_count)
        
        expect(total_rooms).to be >= @room_count,
          "房间数量不足。要求: ≥#{@room_count}间, 实际: #{total_rooms}间"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        @flight_bookings.each do |booking|
          expect(booking.status).to be_in(['pending', 'paid', 'completed'])
        end
        @hotel_bookings.each do |booking|
          expect(booking.status).to be_in(['pending', 'paid', 'completed'])
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择一个航班，创建多张票（多个订单）
      flight = @available_flights.first
      @passenger_count.times do |i|
        Booking.create!(
          user: user,
          flight: flight,
          passenger_name: "乘客#{i + 1}",
          passenger_id_number: "11010119900101#{1234 + i}",
          contact_phone: '13800138000',
          total_price: flight.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 选择一个酒店，预订多个房间
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: @room_count,
        total_price: room.price * @room_count * 3,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        passenger_count: @passenger_count,
        room_count: @room_count
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @passenger_count = data['passenger_count']
      @room_count = data['room_count']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
    end
  end
end
