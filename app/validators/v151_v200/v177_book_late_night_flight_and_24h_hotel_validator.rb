# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例177: 给张三预订明天深夜北京到上海的红眼航班，并在上海预订24小时酒店（航班23:00起飞→次日01:30到达，当晚入住）
#
# 任务描述:
#   张三明天深夜从北京坐红眼航班到上海，航班23:00起飞（例如MU5901 23:00→次日01:30）。
#   因为深夜到达，需要在上海预订有24小时前台服务的酒店，方便凌晨办理入住。
#   重要：酒店入住日期是航班起飞当天（例如3月14日23:00起飞⚒3月14日入住），
#   虽然实际到达是3月15日凌斀01:30，但酒店按自然日计算，凌晨仍算前一天的夜晚。
#   需要创建2个订单：
#   1. 航班订单（明天北京→上海，深夜23:00-次日02:00起飞）
#   2. 酒店订单（航班起飞当天入住上海酒店，次日退房）
#
# 业务流程:
#   1. 搜索并预订明天深夜23:00-次日02:00起飞的红眼航班（北京到上海）
#   2. 记录航班到达时间（次日凌晨）
#   3. 预订上海的酒店（24小时前台服务）
#   4. 入住日期：航班起飞当天（今晚入住，虽然次日凌晨到达但仍算当天的夜晚）
#   5. 退房日期：入住后的第二天
#   6. 乘客和入住人均为张三
#
# 复杂度分析:
#   1. 需要搜索并预订深夜23:00-次日02:00的红眼航班（跨日期时间）
#   2. 需要处理跨日期的时间计算（23:00是今天，01:00是明天）
#   3. 需要理解酒店日期逻辑（航班起飞当天入住，虽然次日凌晨到但算当天夜晚）
#   4. 需要选择有24小时前台服务的酒店（支持凌晨入住）
#   ❌ 不能一次性提供：需要先查询红眼航班时间→确定到达日期→计算酒店入住日期→查找24小时前台酒店→预订航班→预订酒店
#
# 评分标准（总分100分）:
#   1. 创建了航班订单（明天北京→上海） (20分)
#   2. 航班起飞时间正确（23:00-02:00） (18分)
#   3. 创建了酒店订单 (15分)
#   4. 酒店位置正确（上海） (15分)
#   5. 酒店入住日期正确（航班起飞当天） (17分)
#   6. 航班乘客信息正确（张三） (7分)
#   7. 酒店入住人信息正确（张三） (8分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v177_book_late_night_flight_and_24h_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V177BookLateNightFlightAnd24hHotelValidator < BaseValidator
    self.validator_id = 'v177_book_late_night_flight_and_24h_hotel_validator'
    self.task_id = '5d7b3426-da2e-4269-acb8-185afdd1fc1a'
    self.title = '给张三预订明天深夜23:00-次日02:00北京到上海的红眼航班（如MU5901 23:00→01:30），并在上海预订24小时前台酒店'
    self.description = '帮张三订明天深夜23:00-次日02:00的红眼航班从北京到上海（例如MU5901 23:00起飞次日01:30到达），到了上海后找个有24小时前台的酒店，方便凌晨办理入住'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 1.day  # 明天 + 2.days  # 3天后出发
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
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
      
      # 酒店入住日期为航班起飞当天（虽然深夜起飞次日凌晨到达，但酒店按自然日计算，凌晨仍算当天夜晚）
      @hotel_checkin_date = @flight_date
      @hotel_checkout_date = @hotel_checkin_date + 1.day
      
      {
        task: "请为张三预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的红眼航班（23:00-02:00），" \
              "并在#{@arrival_city}预订有24小时前台服务的酒店",
        requirements: {
          passenger: @expected_passenger_name,
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
      
      # 断言2: 航班起飞时间正确（23:00-02:00） (18%)
      add_assertion "航班起飞时间正确（23:00-02:00）", weight: 18 do
        departure_hour = @flight_booking.flight.departure_time.hour
        is_red_eye = departure_hour >= 23 || departure_hour < 2
        expect(is_red_eye).to be(true), 
          "不是红眼航班。期望: 23:00-02:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
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
      
      # 断言4: 酒店在到达城市 (15%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为航班起飞当天 (17%)
      add_assertion "酒店入住日期正确（航班起飞当天）", weight: 17 do
        flight_date = @flight_booking.flight.flight_date
        expect(@hotel_booking.check_in_date).to eq(flight_date),
          "入住日期错误。期望: #{flight_date}（航班起飞当天，虽然次日凌晨到达但仍算当天夜晚）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言6: 航班乘客信息正确（张三） (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（张三） (8%)
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
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用航班和酒店（用于simulate阶段）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select do |f|
          hour = f.departure_time.hour
          (hour >= 23 || hour < 2) && f.flight_date == @flight_date
        end
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
