# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例177: 预订红眼航班和24小时前台酒店
#
# 任务描述:
#   用户需要预订深夜23点到凌晨2点之间的红眼航班，并预订有24小时前台服务的酒店
#
# 复杂度分析:
#   1. 需要筛选23:00-02:00时段的航班
#   2. 需要预订24小时前台服务的酒店
#   3. 需要处理跨日期的时间计算
#   4. 验证酒店入住时间与航班时间的匹配
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 航班起飞时间正确（23:00-02:00） (20分)
#   - 创建了酒店订单 (20分)
#   - 酒店在到达城市 (20分)
#   - 酒店入住日期为航班到达当天 (20分)
module V151V200
  class V177BookLateNightFlightAnd24hHotelValidator < BaseValidator
    self.validator_id = 'v177_book_late_night_flight_and_24h_hotel_validator'
    self.task_id = '5d7b3426-da2e-4269-acb8-185afdd1fc1a'
    self.title = '预订红眼航班和24小时前台酒店'
    self.description = '用户需要预订深夜23点到凌晨2点之间的红眼航班，并预订有24小时前台服务的酒店'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.tomorrow + 2.days  # 3天后出发
      
      # 查找红眼航班（23:00-02:00）
      # 23:00-23:59 is today, 00:00-02:00 is next day
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select do |f|
          hour = f.departure_time.hour
          (hour >= 23 || hour < 2) && f.flight_date == @flight_date
        end
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}红眼航班（23:00-02:00）"
      
      # 查找上海的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 酒店入住日期为航班到达当天（深夜航班可能次日到达）
      sample_flight = @available_flights.first
      @hotel_checkin_date = sample_flight.arrival_time.to_date
      @hotel_checkout_date = @hotel_checkin_date + 1.day
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的红眼航班（23:00-02:00），" \
              "并在#{@arrival_city}预订有24小时前台服务的酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.to_s,
          departure_time_range: "23:00-02:00",
          hotel_location: @arrival_city,
          hotel_service: "24小时前台"
        },
        hint: "红眼航班深夜到达，需要酒店提供24小时入住服务",
        statistics: {
          available_red_eye_flights: @available_flights.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建航班订单
      flight = @available_flights.first
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          name: '标准双人间',
          size: 25.0,
          bed_type: 'double',
          price: 300.0,
          original_price: 400.0,
          amenities: ['免费WiFi', '空调', '热水', '24小时前台'].to_json,
          breakfast_included: false,
          cancellation_policy: '免费取消',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @flight_booking = all_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 航班起飞时间正确（23:00-02:00） (20%)
      add_assertion "航班起飞时间正确（23:00-02:00）", weight: 20 do
        departure_hour = @flight_booking.flight.departure_time.hour
        is_red_eye = departure_hour >= 23 || departure_hour < 2
        expect(is_red_eye).to be(true), 
          "不是红眼航班。期望: 23:00-02:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
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
      
      # 断言4: 酒店在到达城市 (20%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为航班到达当天 (20%)
      add_assertion "酒店入住日期正确（航班到达当天）", weight: 20 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        expect(@hotel_booking.check_in_date).to eq(arrival_date),
          "入住日期错误。期望: #{arrival_date}（航班到达当天）, 实际: #{@hotel_booking.check_in_date}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
    end
  end
end
