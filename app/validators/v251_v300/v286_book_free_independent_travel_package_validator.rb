# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例286: 给张三预订自由行套餐
#
# 任务描述:
#   给张三预订从深圳到北京的机+酒+接送机+保险的自由行套餐
#
# 评分标准:
#   - 创建航班预订 (15%)
#   - 创建酒店预订 (15%)
#   - 创建接送机服务 (10%)
#   - 创建保险订单 (10%)
#   - 航班和酒店城市匹配 (10%)
#   - 航班乘机人信息正确（张三） (10%)
#   - 酒店入住人信息正确（张三） (10%)
#   - 航班出发日期正确 (10%)
#   - 酒店入住/退房日期正确 (10%)
module V251V300
  class V286BookFreeIndependentTravelPackageValidator < BaseValidator
    self.validator_id = 'v286_book_free_independent_travel_package_validator'
    self.task_id = '894541d3-6504-42a4-b182-14e38d262387'
    self.title = '给张三预订从深圳到北京的机+酒+接送+保险的自由行套餐'
    self.description = '给张三预订从深圳到北京的机+酒+接送+保险的自由行套餐'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '北京'
      @departure_date = Date.current + 5.days
      @return_date = @departure_date + 3.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请给张三预订从#{@departure_city}到#{@destination_city}的自由行套餐，包含往返航班、酒店、接送机和旅游保险，#{@departure_date.strftime('%Y年%-m月%-d日')}出发",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        hint: "预订完整的自由行服务：航班、酒店、用车、保险"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 15 do
        @booking = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到航班预订"
      end
      
      add_assertion "创建了酒店预订", weight: 15 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      add_assertion "创建了接送机服务", weight: 10 do
        @transfer = Transfer
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@transfer).not_to be_nil, "未找到接送机服务"
      end
      
      add_assertion "创建了保险订单", weight: 10 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到保险订单"
      end
      
      return unless @booking && @hotel_booking
      
      add_assertion "航班和酒店城市匹配", weight: 10 do
        flight = @booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.destination_city).to eq(hotel.city),
          "航班目的地与酒店城市不匹配。航班: #{flight.destination_city}, 酒店: #{hotel.city}"
      end
      
      add_assertion "航班乘机人信息正确（张三）", weight: 10 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘机人姓名错误。期望: #{@expected_passenger_name}（张三），实际: #{@booking.passenger_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "乘机人联系电话错误。期望: #{@expected_contact_phone}，实际: #{@booking.contact_phone}"
      end
      
      add_assertion "酒店入住人信息正确（张三）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_contact_phone),
          "入住人联系电话错误。期望: #{@expected_contact_phone}，实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "航班出发日期正确", weight: 10 do
        flight = @booking.flight
        booking_date = flight.departure_time.to_date
        expect(booking_date).to eq(@departure_date),
          "航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（5天后），实际: #{booking_date.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "酒店入住/退房日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@departure_date),
          "入住日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（5天后），实际: #{@hotel_booking.check_in_date.strftime('%Y-%m-%d')}"
        expect(@hotel_booking.check_out_date).to eq(@return_date),
          "退房日期错误。期望: #{@return_date.strftime('%Y-%m-%d')}（8天后），实际: #{@hotel_booking.check_out_date.strftime('%Y-%m-%d')}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订航班（选择指定日期的航班）
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0)
        .by_date(@departure_date)
        .first!
      booking = Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        passenger_id_number: zhangsan.id_number,
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
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@return_date - @departure_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 预订接送机服务
      transfer_package = TransferPackage.where(data_version: 0).order(price: :asc).first!
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: transfer_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: "#{@destination_city}机场",
        location_to: hotel.address,
        pickup_datetime: flight.arrival_time,
        passenger_name: zhangsan.name,
        passenger_phone: zhangsan.phone,
        luggage_count: 1,
        total_price: transfer_package.price,
        discount_amount: 0,
        status: 'pending',
        driver_status: 'pending',
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
        insured_persons: [{ name: zhangsan.name, id_number: zhangsan.id_number }],
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
        return_date: @return_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
