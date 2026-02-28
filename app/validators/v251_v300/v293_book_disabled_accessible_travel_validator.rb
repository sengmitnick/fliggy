# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例293: 给王芳预订健康养生出行（广州-上海）
#
# 任务描述:
#   给王芳预订6天后从广州到上海的健康养生出行方案（航班+水疗养生酒店）
#
# 评分标准:
#   - 创建航班预订 (30%)
#   - 创建水疗养生酒店预订 (30%)
#   - 乘客信息正确（王芳）(15%)
#   - 航班和酒店城市匹配 (15%)
#   - 订单状态正确 (10%)
module V251V300
  class V293BookDisabledAccessibleTravelValidator < BaseValidator
    self.validator_id = 'v293_book_disabled_accessible_travel_validator'
    self.task_id = '5a979b48-b8b5-425a-ae5d-8f4b27ee1d4d'
    self.title = '帮王芳订6天后从广州到上海的健康养生出行，她想放松身心，需要水疗养生酒店'
    self.description = '帮王芳订6天后从广州到上海的健康养生出行，她想放松身心，需要水疗养生酒店'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '上海'
      @departure_date = Date.current + 6.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @wangfang.name
      @expected_passenger_id_number = @wangfang.id_number
      @expected_contact_phone = @wangfang.phone
      
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请为王芳预订从#{@departure_city}到#{@destination_city}的健康养生出行方案，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要航班和水疗养生酒店",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "预订航班和水疗养生酒店，让身心得到放松"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 30 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的航班预订"
      end
      
      return unless @booking
      
      add_assertion "创建了水疗养生酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的水疗养生酒店预订"
      end
      
      add_assertion "乘客信息正确（王芳）", weight: 15 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id_number),
          "乘客身份证号错误。期望: #{@expected_passenger_id_number}, 实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@booking.contact_phone}"
      end
      
      return unless @hotel_booking
      
      add_assertion "航班和酒店城市匹配（#{@destination_city}）", weight: 15 do
        flight = @booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.destination_city).to eq(hotel.city),
          "航班目的地与酒店城市不匹配。航班: #{flight.destination_city}, 酒店: #{hotel.city}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_booking_statuses = ['pending', 'paid', 'confirmed']
        valid_hotel_statuses = ['pending', 'paid', 'confirmed']
        
        expect(valid_booking_statuses).to include(@booking.status),
          "航班订单状态错误: #{@booking.status}"
        expect(valid_hotel_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 1. 预订航班
      flight = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: wangfang.name,
        contact_phone: wangfang.phone,
        passenger_id_number: wangfang.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订水疗养生酒店
      hotel = Hotel.where(city: @destination_city, data_version: 0).order(price: :desc).first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @departure_date,
        check_out_date: @departure_date + 2.days,
        guest_name: wangfang.name,
        guest_phone: wangfang.phone,
        payment_method: '花呗',
        total_price: hotel.price * 2,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id_number: @expected_passenger_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id_number = data['expected_passenger_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
