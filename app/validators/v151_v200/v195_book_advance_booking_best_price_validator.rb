# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例195: 给陈静预订15天后从北京到上海的最优价格组合（最便宜的航班+酒店）
#
# 任务描述：
#   为陈静预订15天后从北京到上海的最优价格组合，选择最便宜的航班+最便宜的酒店（提前预订价格更优）
#
# 核心要求：
#   - 乘客：陈静（1人）
#   - 出发日期：15天后（Date.current + 15.days）
#   - 路线：北京 → 上海
#   - 住宿：1晚（入住日期=航班到达日期）
#   - 价格策略：选择最便宜的航班+最便宜的酒店（总价最低）
#   - 预订优势：提前预订通常能获得更优惠的价格
#
# 业务流程：
#   1. 查询15天后北京→上海的所有航班
#   2. 查询上海的所有酒店（按价格升序排序）
#   3. 计算最低组合价格（最便宜航班 + 最便宜酒店）
#   4. 选择最便宜的航班
#   5. 选择最便宜的酒店房间
#   6. 创建航班订单
#   7. 创建酒店订单（入住日期=航班到达日期，住1晚）
#
# 复杂度分析：
#   - 价格优化：贪婪选择（最便宜航班 + 最便宜酒店）
#   - 时间约束：必须是15天后出发的航班
#   - 价格验证：允许5%误差范围（总价 ≤ 最低价 × 1.05）
#
# 验证要点：
#   - 航班/酒店订单已创建
#   - 出发日期为15天后
#   - 乘客和入住人信息正确（陈静）
#   - 价格最优（≤ 最低价 × 1.05）
#   - 城市正确（北京 → 上海）
module V151V200
  class V195BookAdvanceBookingBestPriceValidator < BaseValidator
    self.validator_id = 'v195_book_advance_booking_best_price_validator'
    self.task_id = '6f3a5eb6-ae1b-45cc-ae14-ecec290c6cba'
    self.title = '给陈静预订15天后从北京到上海的最优价格组合（最便宜的航班+酒店）'
    self.description = '帮陈静预订15天后从北京到上海的最优价格组合（最便宜的航班+酒店，提前预订价格更优）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @future_date = Date.current + 15.days
      
      # 查找15天后的航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @future_date }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}在#{@future_date}的航班"
      
      # 查找酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).order(price: :asc).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 计算最低组合价格（最便宜航班 + 最便宜酒店整晚房）
      cheapest_flight_price = @available_flights.min_by(&:price).price.to_f
      cheapest_overnight_room_price = @available_hotels.first.hotel_rooms
        .where(data_version: 0, room_category: 'overnight')
        .minimum(:price).to_f
      @min_price = cheapest_flight_price + cheapest_overnight_room_price
      
      {
        task: "请为#{@passenger.name}预订15天后（#{@future_date.strftime('%m月%d日')}）从#{@departure_city}到#{@arrival_city}的最优价格组合（航班+酒店）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @future_date.strftime('%Y-%m-%d'),
        hint: "提前预订，选择最优价格组合"
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
      
      # 断言3: 出发日期为15天后 (10%)
      add_assertion "出发日期为15天后（#{@future_date}）", weight: 10 do
        flight_date = @flight_booking.flight.departure_time.to_date
        expect(flight_date).to eq(@future_date),
          "出发日期错误。期望: #{@future_date}（15天后）, 实际: #{flight_date}"
      end
      
      # 断言4: 乘客和入住人信息正确（陈静） (15%)
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
      
      # 断言5: 价格最优（最低价或接近，允许5%误差） (15%)
      add_assertion "价格最优（最低价或接近，允许5%误差）", weight: 15 do
        flight_price = @flight_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = flight_price + hotel_price
        
        allowed_max = @min_price * 1.05
        expect(total_price).to be <= allowed_max,
          "价格不是最优。期望: ≤#{allowed_max.round(2)}元（最低价#{@min_price}+5%误差）, 实际: #{total_price}元"
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
      passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 选择最便宜的航班
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
      # CRITICAL: 必须过滤room_category='overnight'，排除钟点房
      room = cheapest_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
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
        future_date: @future_date&.to_s,
        min_price: @min_price,
        available_hotel_ids: @available_hotels&.map(&:id)
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @future_date = Date.parse(data['future_date']) if data['future_date']
      @min_price = data['min_price']
      
      # 恢复available_hotels
      if data['available_hotel_ids']
        @available_hotels = Hotel.where(id: data['available_hotel_ids'], data_version: 0).order(price: :asc).to_a
      end
    end
  end
end
