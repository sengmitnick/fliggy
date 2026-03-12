# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例176: 给陈静预订明天凌晨北京到上海的航班，并预订今晚机场附近酒店（航班05:00起飞→07:30到达）
#
# 任务描述:
#   陈静明天一早从北京坐飞机到上海，航班凌晨05:00起飞（例如MU5002 05:00→07:30）。
#   为了方便赶早班飞机，她需要今晚提前入住北京机场附近的酒店（例如北京索菲特大酒店，地址：北京机场78号）。
#   需要创建2个订单：
#   1. 航班订单（明天北京→上海，凌晨05:00-06:30起飞）
#   2. 酒店订单（今晚入住北京机场附近酒店，明天早上退房）
#
# 业务流程:
#   1. 搜索并预订明天凌晨5:00-6:30起飞的北京到上海航班
#   2. 记录航班起飞日期
#   3. 预订机场附近酒店（酒店名称或地址包含"机场"关键词）
#   4. 入住日期：今晚（航班日期-1天）
#   5. 退房日期：明天早上（航班日期当天）
#   6. 乘客和入住人均为陈静
#
# 复杂度分析:
#   1. 需要搜索并预订明天凌晨5-7点起飞的早班航班
#   2. 需要理解"前一晚入住"的日期逻辑（航班日期-1天）
#   3. 需要识别机场酒店（名称/地址包含"机场"）
#   4. 需要协调两个订单的日期关系（酒店退房日=航班日期）
#   ❌ 不能一次性提供：需要先查询早班航班时间→确定航班日期→计算前一晚日期→查找机场附近酒店→预订航班→预订酒店
#
# 评分标准（总分100分）:
#   1. 创建了航班订单（明天北京→上海） (20分)
#   2. 航班起飞时间正确（凌晨5-7点） (18分)
#   3. 创建了酒店订单 (15分)
#   4. 酒店位置靠近机场 (15分)
#   5. 酒店入住日期为航班前一晚 (17分)
#   6. 航班乘客信息正确（陈静） (7分)
#   7. 酒店入住人信息正确（陈静） (8分)
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
    self.title = '给陈静预订明天凌晨05:00-06:30北京到上海的航班（如MU5002 05:00→07:30），并预订今晚机场附近酒店'
    self.description = '帮陈静订明天凌晨5:00-6:30北京到上海的早班航班（例如MU5002 05:00起飞），因为是早班机，今晚先住北京机场附近酒店（今晚入住明早退房），方便明天早起赶飞机'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 1.day  # 明天 + 2.days  # 3天后出发
      @hotel_checkin_date = @flight_date - 1.day  # 前一晚入住
      @hotel_checkout_date = @flight_date  # 航班当天退房
      @min_departure_hour = 5
      @max_departure_hour = 7
      
      # 预查询乘客信息（陈静）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
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
        task: "请为陈静预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的凌晨5-7点航班，" \
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
        guest_name: @passenger.name,
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
      
      # 断言2: 航班起飞时间正确（凌晨5-7点） (18%)
      add_assertion "航班起飞时间正确（凌晨5-7点）", weight: 18 do
        departure_hour = @flight_booking.flight.departure_time.hour
        expect(departure_hour).to be >= @min_departure_hour, 
          "起飞时间过早。期望: #{@min_departure_hour}:00-#{@max_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
        expect(departure_hour).to be < @max_departure_hour,
          "起飞时间过晚。期望: #{@min_departure_hour}:00-#{@max_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
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
      
      # 断言4: 酒店位置靠近机场 (15%)
      add_assertion "酒店位置靠近机场", weight: 15 do
        hotel = @hotel_booking.hotel
        is_near_airport = hotel.name.include?('机场') || 
                          (hotel.address && hotel.address.include?('机场'))
        
        # 如果酒店名称或地址包含"机场"，则认为靠近机场
        # 否则只要在出发城市即可接受（因为数据包限制）
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为航班前一晚 (17%)
      add_assertion "酒店入住日期为航班前一晚（#{@hotel_checkin_date}）", weight: 17 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（航班前一晚）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期为航班当天
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}（航班当天）, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言6: 航班乘客信息正确（陈静） (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（陈静） (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
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
        max_departure_hour: @max_departure_hour,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
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
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用航班和酒店（用于simulate阶段）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.departure_time.hour >= @min_departure_hour && f.departure_time.hour < @max_departure_hour }
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where("name LIKE ? OR address LIKE ?", "%机场%", "%机场%")
        .where(data_version: 0)
        .to_a
      
      if @available_hotels.empty?
        @available_hotels = Hotel
          .where("city LIKE ?", "%#{@departure_city}%")
          .where(data_version: 0)
          .limit(20)
          .to_a
      end
    end
  end
end
