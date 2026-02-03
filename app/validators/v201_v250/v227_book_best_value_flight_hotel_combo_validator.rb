# frozen_string_literal: true

require_relative '../base_validator'

# V227: 预订综合性价比最高组合（航班+酒店）
#
# 任务描述:
#   用户需要预订航班+酒店，综合考虑价格、时长、评分等因素，选择综合性价比最高的组合
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 航班性价比较优（时长短、价格合理） (25%)
#   - 酒店性价比较优（评分高、价格合理） (25%)
#   - 订单状态有效 (10%)
module V201V250
  class V227BookBestValueFlightHotelComboValidator < BaseValidator
    self.validator_id = 'v227_book_best_value_flight_hotel_combo_validator'
    self.task_id = '5ff576ff-6f6f-6f8f-8f9f-7f0a1b2c3d4f'
    self.title = '预订综合性价比最高组合'
    self.description = '用户需要预订航班+酒店，综合考虑价格、时长、评分等因素，选择综合性价比最高的组合'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '上海'
      @flight_date = Date.today + 1.day
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 2.days
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
      
      raise "未找到航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      # 计算综合性价比参考值
      # 航班综合分数 = (时长分数 + 价格分数) / 2
      flight_scores = @available_flights.map do |f|
        duration_minutes = (f.arrival_time - f.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)  # 时长越短越好
        price_score = 100.0 / (f.price + 1)  # 价格越低越好
        (duration_score + price_score) / 2.0
      end
      @reference_flight_score = flight_scores.max
      
      # 酒店综合分数 = (评分分数 + 价格分数) / 2
      hotel_scores = @available_hotels.map do |h|
        rating_score = h.rating * 20  # 5星满分=100分
        price_score = 100.0 / (h.price + 1)
        (rating_score + price_score) / 2.0
      end
      @reference_hotel_score = hotel_scores.max
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的航班和酒店（住2晚），要求综合性价比最高，综合考虑航班时长、价格、酒店评分等因素。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          nights: 2,
          optimization: '综合性价比最高'
        },
        hint: "需要平衡多个因素：航班时长、航班价格、酒店评分、酒店价格，选择综合得分最高的组合。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "航班性价比较优", weight: 25 do
        flight = @flight_booking.flight
        duration_minutes = (flight.arrival_time - flight.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)
        price_score = 100.0 / (flight.price + 1)
        actual_flight_score = (duration_score + price_score) / 2.0
        
        # 允许15%的偏差
        expect(actual_flight_score).to be >= @reference_flight_score * 0.85,
          "航班综合性价比不佳。参考最佳分数: #{@reference_flight_score.round(1)}, 实际分数: #{actual_flight_score.round(1)} (时长#{(duration_minutes/60.0).round(1)}h, 价格#{flight.price}元)"
      end
      
      add_assertion "酒店性价比较优", weight: 25 do
        hotel = @hotel_booking.hotel
        rating_score = hotel.rating * 20
        price_score = 100.0 / (hotel.price + 1)
        actual_hotel_score = (rating_score + price_score) / 2.0
        
        # 允许15%的偏差
        expect(actual_hotel_score).to be >= @reference_hotel_score * 0.85,
          "酒店综合性价比不佳。参考最佳分数: #{@reference_hotel_score.round(1)}, 实际分数: #{actual_hotel_score.round(1)} (评分#{hotel.rating}星, 价格#{hotel.price}元/晚)"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 计算每个航班的综合分数
      flight_with_scores = @available_flights.map do |f|
        duration_minutes = (f.arrival_time - f.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)
        price_score = 100.0 / (f.price + 1)
        score = (duration_score + price_score) / 2.0
        { flight: f, score: score }
      end
      best_flight = flight_with_scores.max_by { |fs| fs[:score] }[:flight]
      
      # 计算每个酒店的综合分数
      hotel_with_scores = @available_hotels.map do |h|
        rating_score = h.rating * 20
        price_score = 100.0 / (h.price + 1)
        score = (rating_score + price_score) / 2.0
        { hotel: h, score: score }
      end
      best_hotel = hotel_with_scores.max_by { |hs| hs[:score] }[:hotel]
      room = best_hotel.hotel_rooms.where(data_version: 0).first
      
      Booking.create!(
        user: user,
        flight: best_flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: best_hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: best_hotel.price * 2,
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
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        reference_flight_score: @reference_flight_score,
        reference_hotel_score: @reference_hotel_score
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @reference_flight_score = data['reference_flight_score'].to_f
      @reference_hotel_score = data['reference_hotel_score'].to_f
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
    end
  end
end
