# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例190: 预订性价比最高组合
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
    self.title = '给刘强预订明天性价比最高的航班+酒店组合'
    self.description = '帮刘强预订明天从北京到上海的航班+酒店，要求性价比最高（评分/价格比最优）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      
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
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班+酒店，要求性价比最高（评分/价格比最优）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        optimization_target: '性价比最高（评分/价格比）',
        hint: "性价比 = 酒店评分 / 酒店价格，选择比值最大的组合"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单和酒店订单 (20%)
      add_assertion "创建了航班订单和酒店订单", weight: 20 do
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
      
      # 断言2: 出发/到达城市正确 (13%)
      add_assertion "出发/到达城市正确（#{@departure_city}→#{@arrival_city}）", weight: 13 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
      end
      
      # 断言3: 酒店城市正确 (8%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 8 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言4: 日期合理 (8%)
      add_assertion "日期合理", weight: 8 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
      
      # 断言5: 性价比最高（评分/价格比最优，允许10%误差） (30%)
      add_assertion "性价比最高（评分/价格比最优，允许10%误差）", weight: 30 do
        hotel = @hotel_booking.hotel
        actual_value_ratio = hotel.rating.to_f / hotel.price.to_f
        
        min_acceptable_ratio = @best_value_ratio * 0.9
        expect(actual_value_ratio).to be >= min_acceptable_ratio,
          "性价比不是最优。期望: ≥#{min_acceptable_ratio.round(4)}（最佳性价比#{@best_value_ratio.round(4)}-10%误差）, 实际: #{actual_value_ratio.round(4)}（酒店评分#{hotel.rating}/价格#{hotel.price}）"
      end
      
      # 断言6: 航班乘客信息正确 (3%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 3 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
      end
      
      # 断言7: 航班联系电话正确 (7%)
      add_assertion "航班联系电话正确（#{@expected_phone}）", weight: 7 do
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
      
      # 断言8: 酒店入住人信息正确 (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言9: 航班出发日期正确 (3%)
      add_assertion "航班出发日期正确（#{@travel_date}）", weight: 3 do
        actual_date = @flight_booking.flight.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}, 实际: #{actual_date}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      
      # 选择任意航班（性价比主要看酒店）
      flight = @available_flights.min_by(&:price)
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: flight.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 找到性价比最高的酒店（评分/价格比最大）
      best_value_hotel = @available_hotels.max_by { |h| h.rating.to_f / h.price.to_f }
      
      # 创建酒店订单
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = best_value_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      arrival_date = flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: best_value_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
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
        best_value_ratio: @best_value_ratio,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '刘强'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @best_value_ratio = data['best_value_ratio']
      
      # 重建 available 数据
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      @available_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where.not(rating: nil)
        .to_a
    end
  end
end
