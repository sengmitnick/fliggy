# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例184: 给张建国预订今晚上海酒店，并预订明天晚上到北京的航班
#
# 任务描述:
#   张建国需要明天晚上从上海坐飞机到北京（18:00后出发），
#   为了保证出行顺利，需要今晚入住上海酒店。Agent需要搜索晚班航班并预订，
#   然后预订今晚的上海酒店（明天航班当天退房）。
#
# 业务流程（6个关键步骤）：
#   1. 搜索上海→北京的航班（明天18:00后出发）
#   2. 筛选晚班航班（出发时间在 18:00 之后）
#   3. 预订航班票（乘客张建国）
#   4. 搜索上海的酒店
#   5. 选择适合的酒店
#   6. 预订今晚的上海酒店（入住日期=今天，退房日期=明天航班当天）
#
# 复杂度分析（5个关键点）：
#   1. 需要筛选晚班航班（出发时间在 18:00 之后）
#   2. 需要理解时间逻辑：明天晚班航班 → 今晚入住酒店
#   3. 需要识别出发城市（上海）作为酒店位置
#   4. 需要验证酒店退房日期与航班日期匹配
#   5. 需要确保航班和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索航班→筛选晚班→预订航班→理解时间→搜索今晚上海酒店→预订
#
# 评分标准（7项，总计100分）：
#   - 创建了上海酒店订单（20分）
#   - 酒店位置正确（必须在上海）（18分）
#   - 酒店退房日期与航班日期匹配（明天）（17分）
#   - 创建了航班订单（上海→北京）（15分）
#   - 航班是晚上出发（明天18:00后）（15分）
#   - 航班乘客信息正确（张建国）（7分）
#   - 酒店入住人信息正确（张建国）（8分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v184_book_late_checkout_hotel_and_evening_flight_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V184BookLateCheckoutHotelAndEveningFlightValidator < BaseValidator
    self.validator_id = 'v184_book_late_checkout_hotel_and_evening_flight_validator'
    self.task_id = '2fc00235-eef6-4b3e-ab69-d838b5038fd8'
    self.title = '给张建国预订今晚上海酒店，并预订明天晚上到北京的航班'
    self.description = '帮张建国在上海预订酒店，入住今晚，明天退房，并订明天晚上从上海到北京的航班'
    self.timeout_seconds = 300
  
    def prepare
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张建国', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 设置基本参数
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
      
      # 计算酒店入住退房日期
      @hotel_checkin_date = @flight_date - 1.day  # 今晚入住（航班前一晚）
      @hotel_checkout_date = @flight_date  # 明天退房（航班当天）
      
      {
        task: "请为#{@passenger.name}在#{@departure_city}预订酒店，入住#{@hotel_checkin_date.strftime('%Y年%m月%d日')}（今晚），" \
              "退房#{@hotel_checkout_date.strftime('%Y年%m月%d日')}（明天），并预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）晚上从#{@departure_city}到#{@arrival_city}的航班",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          hotel_location: @departure_city,
          hotel_checkin: @hotel_checkin_date.to_s,
          hotel_checkout: @hotel_checkout_date.to_s,
          flight_date: @flight_date.to_s,
          departure_time: "18:00后"
        },
        hint: "晚上航班需要前一晚入住酒店，航班当天退房",
        statistics: {
          available_evening_flights: @available_flights.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张建国', data_version: 0)
      
      # 创建酒店订单（选择适合的酒店）
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
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
      
      # 创建航班订单（选择晚班航班）
      flight = @available_flights.sort_by(&:departure_time).first
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
      # 断言1: 创建了上海酒店订单 (20%)
      add_assertion "创建了上海酒店订单", weight: 20 do
        # 查询上海的酒店订单（使用LIKE模糊匹配城市名）
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where("hotels.city LIKE ?", "%#{@departure_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到上海酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言2: 酒店位置在上海（出发城市） (18%)
      add_assertion "酒店位置正确（必须在#{@departure_city}）", weight: 18 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言3: 酒店退房日期与航班日期匹配（明天） (17%)
      add_assertion "酒店退房日期与航班日期匹配（明天）", weight: 17 do
        # 验证退房日期 = 明天（航班当天）
        expect(@hotel_booking.check_out_date).to eq(@flight_date),
          "退房日期错误。期望: #{@flight_date}（明天，航班当天）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 注: 原任务描述提到“延迟退房”，但数据包中无checkout_time字段，前端也无此标签，因此不验证
      
      # 断言4: 创建了航班订单（上海→北京） (15%)
      add_assertion "创建了航班订单（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        # 查询上海→北京的航班订单（过滤出出发城市和目的地）
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
      
      # 断言5: 航班是晚上出发（明天18:00后） (15%)
      add_assertion "航班是晚上出发（明天18:00后）", weight: 15 do
        # 验证出发时间 >= 18:00
        departure_hour = @flight_booking.flight.departure_time.hour
        expect(departure_hour).to be >= 18, 
          "出发时间过早。期望: 18:00后, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
    
      # 断言6: 航班乘客信息正确（张建国） (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（张建国） (8%)
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
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.departure_time.hour >= 18 }
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
