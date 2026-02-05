# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例293: 预订残障人士无障碍出行
#
# 任务描述:
#   用户预订残障人士无障碍出行方案
#
# 评分标准:
#   - 创建航班预订 (30%)
#   - 创建无障碍酒店预订 (30%)
#   - 创建轮椅租赁服务 (25%)
#   - 订单状态正确 (15%)
module V251V300
  class V293BookDisabledAccessibleTravelValidator < BaseValidator
    self.validator_id = 'v293_book_disabled_accessible_travel_validator'
    self.task_id = '5a979b48-b8b5-425a-ae5d-8f4b27ee1d4d'
    self.title = '预订残障人士无障碍出行'
    self.description = '用户预订残障人士无障碍出行方案'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '上海'
      @departure_date = Date.current + 6.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请为残障人士预订从#{@departure_city}到#{@destination_city}的无障碍出行方案，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要航班、无障碍酒店和轮椅租赁服务",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "预订航班、无障碍酒店和轮椅租赁服务"
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
      
      add_assertion "创建了无障碍酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的无障碍酒店预订"
      end
      
      add_assertion "创建了轮椅租赁服务", weight: 25 do
        @service = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@service).not_to be_nil, "未找到轮椅租赁服务"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        valid_statuses = ['pending', 'paid']
        if @booking
          expect(valid_statuses).to include(@booking.status),
            "航班订单状态错误: #{@booking.status}"
        end
        if @hotel_booking
          expect(valid_statuses).to include(@hotel_booking.status),
            "酒店订单状态错误: #{@hotel_booking.status}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订航班
      flight = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        passenger_id_number: '440300199001011234',
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订无障碍酒店
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
        guest_name: user.name || '张三',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * 2,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 租赁轮椅服务
      car = Car.where(data_version: 0).first!
      CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: user.name || '张三',
        driver_id_number: '440300199001011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @departure_date,
        return_datetime: @departure_date + 2.days,
        pickup_location: "#{@destination_city}机场",
        status: 'pending',
        total_price: 200,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
    end
  end
end
