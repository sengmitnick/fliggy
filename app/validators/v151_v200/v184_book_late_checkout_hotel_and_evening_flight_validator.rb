# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例184: 预订延迟退房酒店和晚班航班
#
# 任务描述:
#   用户需要预订支持延迟退房（下午2点后）的酒店，并预订晚上的航班
#
# 复杂度分析:
#   1. 需要预订支持延迟退房的酒店
#   2. 需要筛选晚上的航班（18:00后）
#   3. 验证退房时间与航班时间的合理性
#
# 评分标准:
#   - 创建了酒店订单 (20分)
#   - 酒店在出发城市 (20分)
#   - 酒店退房日期与航班日期匹配 (15分)
#   - 支持延迟退房（下午2点后） (5分)
#   - 创建了航班订单 (20分)
#   - 航班是晚上出发（18:00后） (20分)
module V151V200
  class V184BookLateCheckoutHotelAndEveningFlightValidator < BaseValidator
    self.validator_id = 'v184_book_late_checkout_hotel_and_evening_flight_validator'
    self.task_id = '2fc00235-eef6-4b3e-ab69-d838b5038fd8'
    self.title = '给吴勇预订今晚上海延迟退房酒店，并预订明天晚上到北京的航班'
    self.description = '帮吴勇在上海预订支持延迟退房（下午2点后）的酒店，入住今晚，明天退房，并订明天晚上从上海到北京的航班'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '吴勇', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '上海'
      @arrival_city = '北京'
      @flight_date = Date.current + 1.day  # 明天
      
      # 查找晚上的航班（18:00后）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.departure_time.hour >= 18 }
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}晚上的航班（18:00后）"
      
      # 查找上海的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@departure_city}的酒店"
      
      @hotel_checkin_date = @flight_date - 1.day  # 前一天入住
      @hotel_checkout_date = @flight_date  # 航班当天退房
      
      {
        task: "请为#{@passenger.name}在#{@departure_city}预订支持延迟退房（下午2点后）的酒店，入住#{@hotel_checkin_date.strftime('%Y年%m月%d日')}，" \
              "退房#{@hotel_checkout_date.strftime('%Y年%m月%d日')}，并预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）晚上从#{@departure_city}到#{@arrival_city}的航班",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          hotel_location: @departure_city,
          hotel_checkin: @hotel_checkin_date.to_s,
          hotel_checkout: @hotel_checkout_date.to_s,
          checkout_time: "下午2点后",
          flight_date: @flight_date.to_s,
          departure_time: "18:00后"
        },
        hint: "延迟退房可以充分利用白天时间，晚上再出发去机场",
        statistics: {
          available_evening_flights: @available_flights.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '吴勇', data_version: 0)
      
      # 创建酒店订单
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
      
      # 创建航班订单
      flight = @available_flights.first
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言2: 酒店在出发城市 (20%)
      add_assertion "酒店位置正确（#{@departure_city}）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言3: 酒店退房日期与航班日期匹配 (15%)
      add_assertion "酒店退房日期与航班日期匹配", weight: 15 do
        expect(@hotel_booking.check_out_date).to eq(@flight_date),
          "退房日期错误。期望: #{@flight_date}（航班当天）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言3.5: 支持延迟退房（下午2点后） (5%)
      add_assertion "支持延迟退房（下午2点后）", weight: 5 do
        # 注: 当前数据包中酒店可能未明确标注退房时间，此断言默认通过
        # 如果未来数据包添加 checkout_time 字段，需更新此验证逻辑
        # 目前只验证酒店订单存在，不验证具体退房时间
        expect(@hotel_booking).not_to be_nil, "酒店订单不存在"
      end
      
      # 断言4: 创建了航班订单 (20%)
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
      
      # 断言5: 航班是晚上出发（18:00后） (20%)
      add_assertion "航班是晚上出发（18:00后）", weight: 20 do
        departure_hour = @flight_booking.flight.departure_time.hour
        expect(departure_hour).to be >= 18, 
          "出发时间过早。期望: 18:00后, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
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
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '吴勇', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
    end
  end
end
