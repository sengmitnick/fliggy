# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例286: 预订自由行套餐
#
# 任务描述:
#   用户预订机+酒+接送+保险的自由行套餐
#
# 评分标准:
#   - 创建航班预订 (20%)
#   - 创建酒店预订 (20%)
#   - 创建用车订单 (20%)
#   - 创建保险订单 (15%)
#   - 所有服务衔接合理 (15%)
#   - 所有订单状态正确 (10%)
module V251V300
  class V286BookFreeIndependentTravelPackageValidator < BaseValidator
    self.validator_id = 'v286_book_free_independent_travel_package_validator'
    self.task_id = '894541d3-6504-42a4-b182-14e38d262387'
    self.title = '预订自由行套餐'
    self.description = '用户预订机+酒+接送+保险的自由行套餐'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '北京'
      @departure_date = Date.current + 5.days
      @return_date = @departure_date + 3.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的自由行套餐，包含往返航班、酒店、接送机和旅游保险，#{@departure_date.strftime('%Y年%-m月%-d日')}出发",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        hint: "预订完整的自由行服务：航班、酒店、用车、保险"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 20 do
        @booking = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到航班预订"
      end
      
      add_assertion "创建了酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      add_assertion "创建了用车/接送服务", weight: 20 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@car_order).not_to be_nil, "未找到用车/接送服务"
      end
      
      add_assertion "创建了保险订单", weight: 15 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到保险订单"
      end
      
      return unless @booking && @hotel_booking
      
      add_assertion "航班和酒店城市匹配", weight: 15 do
        flight = @booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.destination_city).to eq(hotel.city),
          "航班目的地与酒店城市不匹配。航班: #{flight.destination_city}, 酒店: #{hotel.city}"
      end
      
      add_assertion "所有订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@booking.status),
          "航班订单状态错误: #{@booking.status}"
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订航班
      flight = Flight.where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0).first!
      booking = Booking.create!(
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
      
      # 2. 预订酒店
      hotel = Hotel.where(city: @destination_city, data_version: 0).first!
      hotel_booking = HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @departure_date,
        check_out_date: @return_date,
        guest_name: user.name || '张三',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * (@return_date - @departure_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 预订用车
      car = Car.where(data_version: 0).first!
      car_order = CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: user.name || '张三',
        driver_id_number: '440300199001011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @departure_date,
        return_datetime: @departure_date + 1.day,
        pickup_location: "#{@destination_city}机场",
        status: 'pending',
        total_price: car.price_per_day,
        data_version: @data_version
      )
      
      # 4. 预订保险
      insurance_product = InsuranceProduct.where(data_version: 0).first!
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @departure_date,
        end_date: @return_date,
        days: (@return_date - @departure_date).to_i,
        insured_persons: [{ name: user.name || '张三', id_number: '440300199001011234' }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * (@return_date - @departure_date).to_i,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
    end
  end
end
