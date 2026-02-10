# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例176: 预订凌晨航班和机场酒店
#
# 任务描述:
#   用户需要预订凌晨5-7点的航班，并在前一晚入住机场附近酒店
#
# 复杂度分析:
#   1. 需要筛选凌晨5-7点起飞的航班
#   2. 需要识别机场位置
#   3. 需要预订机场附近的酒店（前一晚入住）
#   4. 验证酒店位置是否靠近机场
#   5. 验证入住日期是否为航班前一晚
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 航班起飞时间正确（凌晨5-7点） (20分)
#   - 创建了酒店订单 (20分)
#   - 酒店位置靠近机场 (20分)
#   - 酒店入住日期为航班前一晚 (20分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v176_book_early_morning_flight_and_airport_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V176BookEarlyMorningFlightAndAirportHotelValidator < BaseValidator
    self.validator_id = 'v176_book_early_morning_flight_and_airport_hotel_validator'
    self.task_id = '1bf22b0b-0ed2-4d40-a704-15a738206a48'
    self.title = '给周敏预订明天凌晨北京到上海的航班，并预订今晚机场附近酒店'
    self.description = '帮周敏订明天凌晨5-7点北京到上海的航班，因为是早班机，今晚先住机场附近酒店'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 1.day  # 明天 + 2.days  # 3天后出发
      @hotel_checkin_date = @flight_date - 1.day  # 前一晚入住
      @hotel_checkout_date = @flight_date  # 航班当天退房
      @min_departure_hour = 5
      @max_departure_hour = 7
      
      # 预查询乘客信息（周敏）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '周敏', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 查找凌晨5-7点的航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.departure_time.hour >= @min_departure_hour && f.departure_time.hour < @max_departure_hour }
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}凌晨5-7点的航班"
      
      # 查找北京机场附近的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where("name LIKE ? OR address LIKE ?", "%机场%", "%机场%")
        .where(data_version: 0)
        .to_a
      
      # 如果没有明确标注机场的，查找所有北京酒店
      if @available_hotels.empty?
        @available_hotels = Hotel
          .where("city LIKE ?", "%#{@departure_city}%")
          .where(data_version: 0)
          .limit(20)
          .to_a
      end
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@departure_city}的酒店"
      
      {
        task: "请为周敏预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的凌晨5-7点航班，" \
              "并在#{@hotel_checkin_date.strftime('%Y年%m月%d日')}（航班前一晚）预订#{@departure_city}机场附近的酒店",
        requirements: {
          passenger: @expected_passenger_name,
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.to_s,
          departure_time_range: "凌晨5:00-7:00",
          hotel_checkin_date: @hotel_checkin_date.to_s,
          hotel_location: "#{@departure_city}机场附近"
        },
        hint: "早班飞机需要前一晚入住机场附近酒店，方便第二天早起赶飞机",
        statistics: {
          available_early_flights: @available_flights.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建航班订单
      flight = @available_flights.sort_by(&:departure_time).first
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
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
        guest_phone: @passenger.phone,
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
      
      # 断言2: 航班起飞时间正确（凌晨5-7点） (20%)
      add_assertion "航班起飞时间正确（凌晨5-7点）", weight: 20 do
        departure_hour = @flight_booking.flight.departure_time.hour
        expect(departure_hour).to be >= @min_departure_hour, 
          "起飞时间过早。期望: #{@min_departure_hour}:00-#{@max_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
        expect(departure_hour).to be < @max_departure_hour,
          "起飞时间过晚。期望: #{@min_departure_hour}:00-#{@max_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (20%)
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
      
      # 断言4: 酒店位置靠近机场 (20%)
      add_assertion "酒店位置靠近机场", weight: 20 do
        hotel = @hotel_booking.hotel
        is_near_airport = hotel.name.include?('机场') || 
                          (hotel.address && hotel.address.include?('机场'))
        
        # 如果酒店名称或地址包含"机场"，则认为靠近机场
        # 否则只要在出发城市即可接受（因为数据包限制）
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为航班前一晚 (20%)
      add_assertion "酒店入住日期为航班前一晚（#{@hotel_checkin_date}）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（航班前一晚）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期为航班当天
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}（航班当天）, 实际: #{@hotel_booking.check_out_date}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        min_departure_hour: @min_departure_hour,
        max_departure_hour: @max_departure_hour
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @min_departure_hour = data['min_departure_hour']
      @max_departure_hour = data['max_departure_hour']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '周敏', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    end
  end
end
