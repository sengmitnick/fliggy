# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例195: 预订15天后出发的最优价格组合
#
# 任务描述:
#   预订15天后出发的最优价格组合
#
# 评分标准:
#   - 创建了航班订单 (25%)
#   - 创建了酒店订单 (25%)
#   - 出发日期为15天后 (15%)
#   - 价格最优（最低价或接近） (25%)
#   - 城市正确 (10%)
module V151V200
  class V195BookAdvanceBookingBestPriceValidator < BaseValidator
    self.validator_id = 'v195_book_advance_booking_best_price_validator'
    self.task_id = '6f3a5eb6-ae1b-45cc-ae14-ecec290c6cba'
    self.title = '预订15天后出发的最优价格组合'
    self.description = '预订15天后出发的最优价格组合'
    self.timeout_seconds = 300
    
    def prepare
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
      
      # 计算最低组合价格
      @min_price = @available_flights.min_by(&:price).price.to_f + @available_hotels.first.price.to_f
      
      {
        task: "请预订15天后（#{@future_date.strftime('%m月%d日')}）从#{@departure_city}到#{@arrival_city}的最优价格组合（航班+酒店）",
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
      
      # 断言3: 出发日期为15天后 (15%)
      add_assertion "出发日期为15天后（#{@future_date}）", weight: 15 do
        flight_date = @flight_booking.flight.departure_time.to_date
        expect(flight_date).to eq(@future_date),
          "出发日期错误。期望: #{@future_date}（15天后）, 实际: #{flight_date}"
      end
      
      # 断言4: 价格最优（最低价或接近，允许5%误差） (25%)
      add_assertion "价格最优（最低价或接近，允许5%误差）", weight: 25 do
        flight_price = @flight_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = flight_price + hotel_price
        
        allowed_max = @min_price * 1.05
        expect(total_price).to be <= allowed_max,
          "价格不是最优。期望: ≤#{allowed_max.round(2)}元（最低价#{@min_price}+5%误差）, 实际: #{total_price}元"
      end
      
      # 断言5: 城市正确 (10%)
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
      
      # 选择最便宜的航班
      cheapest_flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: cheapest_flight.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: cheapest_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 选择最便宜的酒店
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: cheapest_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: cheapest_hotel.price,
          original_price: cheapest_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      arrival_date = cheapest_flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
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
        min_price: @min_price
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @future_date = Date.parse(data['future_date']) if data['future_date']
      @min_price = data['min_price']
    end
  end
end
