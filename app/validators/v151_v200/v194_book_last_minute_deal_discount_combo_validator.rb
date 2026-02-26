# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例194: 给张三预订明天出发的特价组合
#
# 任务描述:
#   预订明天出发的特价组合（航班+酒店）
#
# 评分标准:
#   - 创建了航班订单 (25%)
#   - 创建了酒店订单 (25%)
#   - 出发日期为明天 (10%)
#   - 乘客和入住人信息正确（刘强） (15%)
#   - 价格较低（属于特价） (15%)
#   - 城市正确 (10%)
module V151V200
  class V194BookLastMinuteDealDiscountComboValidator < BaseValidator
    self.validator_id = 'v194_book_last_minute_deal_discount_combo_validator'
    self.task_id = 'e5dc7f50-cb89-4ef1-baa8-81e296f08452'
    self.title = '给张三预订明天出发的特价组合'
    self.description = '预订明天出发的特价组合'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @tomorrow = Date.current + 1.day  # 明天
      
      # 查找明天的航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @tomorrow }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}明天（#{@tomorrow}）的航班"
      
      # 查找酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).order(price: :asc).limit(20).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 计算特价阈值（平均价格的80%）
      avg_flight_price = @available_flights.sum(&:price) / @available_flights.size.to_f
      @discount_threshold = avg_flight_price * 0.8
      
      {
        task: "请为#{@passenger.name}预订明天（#{@tomorrow.strftime('%m月%d日')}）从#{@departure_city}到#{@arrival_city}的特价组合（航班+酒店）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @tomorrow.strftime('%Y-%m-%d'),
        hint: "明天出发，选择特价航班和酒店"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (25%)
      add_assertion "创建了航班订单", weight: 25 do
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 创建了酒店订单 (25%)
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 出发日期为明天 (10%)
      add_assertion "出发日期为明天（#{@tomorrow}）", weight: 10 do
        flight_date = @flight_booking.flight.departure_time.to_date
        expect(flight_date).to eq(@tomorrow),
          "出发日期错误。期望: #{@tomorrow}（明天）, 实际: #{flight_date}"
      end
      
      # 断言4: 乘客和入住人信息正确（刘强） (15%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 15 do
        # 检查航班乘客姓名
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        
        # 检查航班联系人
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系人电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言5: 价格较低（属于特价） (15%)
      add_assertion "价格较低（属于特价）", weight: 15 do
        flight_price = @flight_booking.total_price.to_f
        hotel_price = @hotel_booking.total_price.to_f
        total_price = flight_price + hotel_price
        
        # 特价标准：总价 ≤ (平均航班价格 + 平均酒店价格) * 0.9
        avg_hotel_price = @available_hotels.first(10).sum { |h| h.price.to_f } / 10.to_f
        price_threshold = (@discount_threshold.to_f + avg_hotel_price) * 0.9
        
        expect(total_price).to be <= price_threshold,
          "价格不够优惠。期望: ≤#{price_threshold.round(2)}元（特价标准）, 实际: #{total_price.round(2)}元"
      end
      
      # 断言6: 城市正确 (10%)
      add_assertion "城市正确", weight: 10 do
        flight = @flight_booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
        expect(hotel.city).to eq(@arrival_city)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # 选择最便宜的航班（特价）
      cheapest_flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: cheapest_flight.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: cheapest_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 选择最便宜的酒店
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = cheapest_flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        tomorrow: @tomorrow&.to_s,
        discount_threshold: @discount_threshold
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @tomorrow = Date.parse(data['tomorrow']) if data['tomorrow']
      @discount_threshold = data['discount_threshold']
    end
  end
end