# frozen_string_literal: true

require_relative '../base_validator'

# V236: 预订多人出行（订多张票/多个房间）
#
# 任务描述:
#   用户需要为多人预订（如家庭出行，订2张机票+2个房间）
#
# 评分标准:
#   - 创建了航班订单 (15%)
#   - 乘客数量正确（≥2人） (15%)
#   - 航班日期正确 (5%)
#   - 乘客信息正确 (5%)
#   - 创建了酒店订单 (15%)
#   - 房间数量正确（≥2间） (15%)
#   - 酒店入住日期正确 (5%)
#   - 入住人信息正确 (5%)
#   - 订单状态有效 (20%)
module V201V250
  class V236BookMultiplePeopleValidator < BaseValidator
    self.validator_id = 'v236_book_multiple_people_validator'
    self.task_id = '2ff2e3ff-3f3f-3f5f-5f6f-4f7a8b9c0d1f'
    self.title = '给张三等4人预订5天后北京到三亚的航班和酒店（4张机票+2间房）'
    self.description = '帮张三、王芳、小明、李四这4个人订5天后从北京到三亚的机票和酒店，要4张机票和2个房间，住3晚'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @travel_date = Date.current + 5.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 3.days
      @passenger_count = 4  # 4人家庭
      @room_count = 2  # 2个房间
      
      # 查询demo_user和4位乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = demo_user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = demo_user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = demo_user.passengers.find_by!(name: '小明', data_version: 0)
      @lisi = demo_user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_phone = @zhangsan.phone
      @expected_passenger_names = [@zhangsan.name, @wangfang.name, @xiaoming.name, @lisi.name]
      
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
      add_assertion "创建了航班订单", weight: 15 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_bookings = all_bookings
        expect(@flight_bookings).not_to be_empty, "未找到航班订单"
      end
      
      return if @flight_bookings.empty?
      
      add_assertion "乘客数量正确（≥#{@passenger_count}人）", weight: 15 do
        # 统计订单数量（每个订单代表一张机票）
        total_passengers = @flight_bookings.size
        
        expect(total_passengers).to be >= @passenger_count,
          "乘客数量不足。要求: ≥#{@passenger_count}人, 实际: #{total_passengers}人"
      end
      
      add_assertion "航班日期正确（#{@travel_date}）", weight: 5 do
        @flight_bookings.each do |booking|
          expect(booking.flight.flight_date).to eq(@travel_date),
            "航班日期错误。期望: #{@travel_date}, 实际: #{booking.flight.flight_date}"
        end
      end
      
      add_assertion "联系电话正确（#{@expected_contact_phone}）", weight: 5 do
        @flight_bookings.each do |booking|
          expect(booking.contact_phone).to eq(@expected_contact_phone),
            "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{booking.contact_phone}"
        end
      end
      
      add_assertion "创建了酒店订单", weight: 15 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @hotel_bookings = all_hotel_bookings
        expect(@hotel_bookings).not_to be_empty, "未找到酒店订单"
      end
      
      return if @hotel_bookings.empty?
      
      add_assertion "房间数量正确（≥#{@room_count}间）", weight: 15 do
        total_rooms = @hotel_bookings.sum(&:room_count)
        
        expect(total_rooms).to be >= @room_count,
          "房间数量不足。要求: ≥#{@room_count}间, 实际: #{total_rooms}间"
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}, 实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}, 实际: #{booking.check_out_date}"
        end
      end
      
      add_assertion "入住人电话正确", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.guest_phone).to eq(@expected_contact_phone),
            "入住人电话错误。期望: #{@expected_contact_phone}, 实际: #{booking.guest_phone}"
        end
      end
      
      add_assertion "订单状态有效", weight: 20 do
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
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      passengers = [zhangsan, wangfang, xiaoming, lisi]
      
      # 选择一个航班，创建4张票（4个订单）
      flight = @available_flights.first
      passengers.each do |passenger|
        Booking.create!(
          user: user,
          flight: flight,
          passenger_name: passenger.name,
          passenger_id_number: passenger.id_number,
          contact_phone: zhangsan.phone,
          total_price: flight.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 选择一个酒店，预订2个房间
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
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
        room_count: @room_count,
        expected_contact_phone: @expected_contact_phone,
        expected_passenger_names: @expected_passenger_names
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
      @expected_contact_phone = data['expected_contact_phone']
      @expected_passenger_names = data['expected_passenger_names']
      
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
