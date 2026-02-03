# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例506: 预订性价比最高组合
#
# 任务描述:
#   预订性价比最高组合（评分/价格比最优）
#
# 评分标准:
#   - 创建了航班订单和酒店订单 (25%)
#   - 出发/到达城市正确 (15%)
#   - 酒店城市正确 (10%)
#   - 日期合理 (10%)
#   - 性价比最高（评分/价格比最优，允许10%误差） (40%)
module V151V200
  class V190BookBestValueFlightHotelRatingPriceValidator < BaseValidator
    self.validator_id = 'v190_book_best_value_flight_hotel_rating_price_validator'
    self.task_id = '19700fc3-d99e-4691-bf05-a9d0b855d17a'
    self.title = '预订性价比最高组合'
    self.description = '预订性价比最高组合（评分/价格比最优）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 2.days
      
      # 查找航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的航班（#{@travel_date}）"
      
      # 查找酒店（必须有rating）
      @available_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where.not(rating: nil)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的有评分酒店"
      
      # 计算最佳性价比（评分/价格比）
      @best_value_ratio = calculate_best_value_ratio
      
      {
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班+酒店，要求性价比最高（评分/价格比最优）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        optimization_target: '性价比最高（评分/价格比）',
        hint: "性价比 = 酒店评分 / 酒店价格，选择比值最大的组合"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单和酒店订单 (25%)
      add_assertion "创建了航班订单和酒店订单", weight: 25 do
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单（#{@departure_city}→#{@arrival_city}）"
        
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @flight_booking.nil? || @hotel_booking.nil?
      
      # 断言2: 出发/到达城市正确 (15%)
      add_assertion "出发/到达城市正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
      end
      
      # 断言3: 酒店城市正确 (10%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 10 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言4: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
      
      # 断言5: 性价比最高（评分/价格比最优，允许10%误差） (40%)
      add_assertion "性价比最高（评分/价格比最优，允许10%误差）", weight: 40 do
        hotel = @hotel_booking.hotel
        actual_value_ratio = hotel.rating.to_f / hotel.price.to_f
        
        min_acceptable_ratio = @best_value_ratio * 0.9
        expect(actual_value_ratio).to be >= min_acceptable_ratio,
          "性价比不是最优。期望: ≥#{min_acceptable_ratio.round(4)}（最佳性价比#{@best_value_ratio.round(4)}-10%误差）, 实际: #{actual_value_ratio.round(4)}（酒店评分#{hotel.rating}/价格#{hotel.price}）"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择任意航班（性价比主要看酒店）
      flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: flight.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 找到性价比最高的酒店（评分/价格比最大）
      best_value_hotel = @available_hotels.max_by { |h| h.rating.to_f / h.price.to_f }
      
      # 创建酒店订单
      room = best_value_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: best_value_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: best_value_hotel.price,
          original_price: best_value_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: best_value_hotel.id,
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
    
    def calculate_best_value_ratio
      @available_hotels.map { |h| h.rating.to_f / h.price.to_f }.max
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        best_value_ratio: @best_value_ratio
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @best_value_ratio = data['best_value_ratio']
    end
  end
end
