# frozen_string_literal: true

require_relative '../base_validator'

# V163BookRoundTripFlightAndHotelValidator
# 验证用例163: 给张三预订明天北京到上海的往返航班（去程明天，返程第6天），并预订上海酒店5晚住宿（明天入住，第6天退房）
#
# 任务描述:
#   张三计划预订北京到上海的往返航班和酒店住宿：明天出发去上海，在上海住5晚，第6天退房并返回北京。
#   1. 去程航班（明天北京→上海）
#   2. 返程航班（第6天上海→北京）
#   3. 酒店住宿（明天入住上海酒店，住5晚后第6天退房当天返航）
#
# 任务分解步骤:
#   1. 查询去程航班（明天北京→上海，从Flight获取最便宜航班）
#   2. 查询返程航班（第6天上海→北京，从Flight获取最便宜航班）
#   3. 创建去程航班订单（乘客=张三，联系人=张三）
#   4. 创建返程航班订单（乘客=张三，联系人=张三）
#   5. 查询上海酒店（从Hotel获取上海酒店）
#   6. 创建酒店订单（明天入住，住5晚后第6天退房，退房当天返航，入住人=张三）
#
# 评分标准（总分100分）:
#   1. 创建了往返航班订单 (20分)
#   2. 去程航班正确（北京→上海） (20分)
#   3. 去程日期正确（明天） (10分)
#   4. 返程航班正确（上海→北京） (10分)
#   5. 返程日期正确（第6天） (10分)
#   6. 创建了酒店订单 (10分)
#   7. 酒店入住日期和时长正确（明天入住，住5晚，第6天退房） (10分)
#   8. 乘客信息正确（张三） (5分)
#   9. 酒店入住人信息正确（张三） (5分)

module V151V200
  class V163BookRoundTripFlightAndHotelValidator < BaseValidator
    self.validator_id = 'v163_book_round_trip_flight_and_hotel_validator'
    self.task_id = 'a3b4c5d6-7e8f-9a0b-1c2d-3e4f5a6b7c8d'
    self.title = '给张三预订明天北京到上海的往返航班（去程明天，返程第6天），并预订上海酒店5晚住宿（明天入住，第6天退房）'
    self.description = '给张三预订明天北京到上海的往返航班和酒店住宿：去程明天出发，返程第6天返回，酒店明天入住，住5晚后第6天退房当天返航'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.current + 1.day  # 明天出发
      @return_date = @outbound_date + 5.days  # 第6天返回
      @nights = 5  # 住5晚，第6天退房当天返航
      
      # 预查询demo_user的乘客信息（张三作为乘客和联系人）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找去程航班（明天北京→上海）
      @available_outbound_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @outbound_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_outbound_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的航班（明天#{@outbound_date}）"
      
      # 查找返程航班（第6天上海→北京）
      @available_return_flights = Flight
        .where(departure_city: @arrival_city, destination_city: @departure_city, flight_date: @return_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_return_flights).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程航班（第6天#{@return_date}）"
      
      # 查找上海酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建往返航班订单（ONE订单包含去程和返程）
      outbound_flight = @available_outbound_flights.first
      return_flight = @available_return_flights.first
      
      total_price = outbound_flight.price + return_flight.price
      
      Booking.create!(
        user: user,
        flight: outbound_flight,  # 去程航班
        return_flight: return_flight,  # 返程航班
        return_date: return_flight.flight_date,
        trip_type: 'round_trip',  # 往返类型
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: total_price,  # 去程+返程总价
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单（明天入住，住5晚，第6天退房）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      # 计算酒店入住日期和退房日期
      hotel_checkin_date = @outbound_date  # 明天入住
      hotel_checkout_date = hotel_checkin_date + @nights.days  # 第6天退房（返航当天）
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: hotel_checkin_date,
        check_out_date: hotel_checkout_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        payment_method: '花呗',
        total_price: room.price * @nights,
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        nights: @nights,
        expected_name: @expected_name,
        expected_phone: @expected_phone,
        expected_id_number: @expected_id_number
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @nights = data['nights']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_id_number = data['expected_id_number']
    end

    def verify
      # 断言1: 创建了往返航班订单（支持两种模式：一个round_trip订单或两个one_way订单）
      add_assertion "创建了往返航班订单", weight: 20 do
        # 方式1: 查找一个round_trip订单
        @round_trip_booking = Booking
          .where(trip_type: 'round_trip', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        # 方式2: 查找两个one_way订单（去程+返程）
        if @round_trip_booking.nil?
          all_bookings = Booking
            .joins(:flight)
            .where(data_version: @data_version, trip_type: 'one_way')
            .order(created_at: :desc)
            .to_a
          
          @outbound_booking = all_bookings.find do |b|
            b.flight.departure_city == @departure_city &&
            b.flight.destination_city == @arrival_city &&
            b.flight.flight_date == @outbound_date
          end
          
          @return_booking = all_bookings.find do |b|
            b.flight.departure_city == @arrival_city &&
            b.flight.destination_city == @departure_city &&
            b.flight.flight_date == @return_date
          end
          
          expect(@outbound_booking).not_to be_nil, "未找到去程航班订单（#{@departure_city}→#{@arrival_city}）"
          expect(@return_booking).not_to be_nil, "未找到返程航班订单（#{@arrival_city}→#{@departure_city}）"
        else
          expect(@round_trip_booking).not_to be_nil, "未找到往返航班订单"
        end
      end
      
      return if @round_trip_booking.nil? && (@outbound_booking.nil? || @return_booking.nil?)
      
      # 断言2: 去程航班正确（北京→上海）
      add_assertion "去程航班正确（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        outbound_flight = @round_trip_booking ? @round_trip_booking.flight : @outbound_booking.flight
        
        expect(outbound_flight.departure_city).to eq(@departure_city),
          "去程出发城市错误。期望: #{@departure_city}, 实际: #{outbound_flight.departure_city}"
        expect(outbound_flight.destination_city).to eq(@arrival_city),
          "去程目的城市错误。期望: #{@arrival_city}, 实际: #{outbound_flight.destination_city}"
      end
      
      # 断言3: 去程日期正确（明天）
      add_assertion "去程日期正确（明天）", weight: 10 do
        outbound_flight = @round_trip_booking ? @round_trip_booking.flight : @outbound_booking.flight
        expected_outbound_date = @outbound_date
        
        expect(outbound_flight.flight_date).to eq(expected_outbound_date),
          "去程日期错误。期望: #{expected_outbound_date}（明天）, 实际: #{outbound_flight.flight_date}"
      end
      
      # 断言4: 返程航班正确（上海→北京）
      add_assertion "返程航班正确（#{@arrival_city}→#{@departure_city}）", weight: 10 do
        return_flight = @round_trip_booking ? @round_trip_booking.return_flight : @return_booking.flight
        
        expect(return_flight).not_to be_nil, "未找到返程航班信息"
        expect(return_flight.departure_city).to eq(@arrival_city),
          "返程出发城市错误。期望: #{@arrival_city}, 实际: #{return_flight.departure_city}"
        expect(return_flight.destination_city).to eq(@departure_city),
          "返程目的城市错误。期望: #{@departure_city}, 实际: #{return_flight.destination_city}"
      end
      
      # 断言5: 返程日期正确（第6天）
      add_assertion "返程日期正确（第6天）", weight: 10 do
        return_flight = @round_trip_booking ? @round_trip_booking.return_flight : @return_booking.flight
        expected_return_date = @return_date
        
        expect(return_flight.flight_date).to eq(expected_return_date),
          "返程日期错误。期望: #{expected_return_date}（第6天）, 实际: #{return_flight.flight_date}"
      end
      
      # 断言6: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 10 do
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
      
      # 断言7: 酒店入住日期和时长正确（明天入住，住5晚，第6天退房）
      add_assertion "酒店入住日期和时长正确（明天入住，住5晚，第6天退房）", weight: 10 do
        # 动态计算期望的入住日期和退房日期（基于去程和返程航班日期）
        outbound_flight = @round_trip_booking ? @round_trip_booking.flight : @outbound_booking.flight
        return_flight = @round_trip_booking ? @round_trip_booking.return_flight : @return_booking.flight
        expected_checkin = outbound_flight.flight_date  # 明天（去程当天）
        expected_checkout = return_flight.flight_date  # 第6天退房（返航当天）
        
        expect(@hotel_booking.check_in_date).to eq(expected_checkin),
          "入住日期错误。期望: #{expected_checkin}（去程#{outbound_flight.flight_date.strftime('%m月%d日')}当天/明天）, 实际: #{@hotel_booking.check_in_date}"
        
        expect(@hotel_booking.check_out_date).to eq(expected_checkout),
          "退房日期错误。期望: #{expected_checkout}（返航#{return_flight.flight_date.strftime('%m月%d日')}当天/第6天）, 实际: #{@hotel_booking.check_out_date}"
        
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言8: 乘客信息正确（张三）
      add_assertion "乘客信息正确（#{@expected_name}）", weight: 5 do
        booking_to_check = @round_trip_booking || @outbound_booking
        
        expect(booking_to_check.passenger_name).to eq(@expected_name),
          "乘客姓名错误。期望: #{@expected_name}, 实际: #{booking_to_check.passenger_name}"
        expect(booking_to_check.passenger_id_number).to eq(@expected_id_number),
          "乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{booking_to_check.passenger_id_number}"
      end
      
      # 断言9: 酒店入住人信息正确（张三）
      add_assertion "酒店入住人信息正确（#{@expected_name}）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_name),
          "酒店入住人姓名错误。期望: #{@expected_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
  end
end
