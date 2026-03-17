# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例212: 张三需要预订明天深夜23:00后到上海的航班，并预订上海酒店凌晨入住
#
# 任务描述:
#   张三明天需要乘坐深夜航班到上海（起飞时间≥23:00），到达后直接凌晨入住酒店。
#   Agent需要理解深夜航班+凌晨入住的业务场景，确保航班和酒店时间衔接合理。
#
# 业务流程:
#   1. 查找明天到上海的深夜航班（起飞时间≥23:00）
#   2. 查找上海的酒店
#   3. 确定航班到达日期（可能是次日凌晨）
#   4. 创建航班订单
#   5. 创建酒店订单（入住日期=航班到达日期）
#
# 复杂度分析:
#   1. 需要理解深夜航班的业务场景（23:00后起飞，可能次日凌晨到达）
#   2. 需要计算航班到达时间对应的日期（跨日逻辑）
#   3. 需要理解酒店入住日期应为航班到达日期（不是出发日期）
#   4. 需要理解凌晨入住是常见场景（不需要特殊酒店标签）
#
# 评分标准:
#   - 创建了航班和酒店订单 (15分)
#   - 航班到达城市正确（上海） (10分)
#   - 航班出发日期正确（明天） (10分)
#   - 航班起飞时间≥23:00 (15分)
#   - 酒店位于上海 (10分)
#   - 酒店入住日期正确（凌晨到达应算前一天） (25分)
#   - 乘客/入住人信息正确 (10分)
#   - 订单状态有效 (5分)
module V201V250
  class V212BookHotelCheckInAfterMidnightValidator < BaseValidator
    self.validator_id = 'v212_book_hotel_check_in_after_midnight_validator'
    self.task_id = '1fc243f6-2f2f-4f5f-ff5f-6f8a9b0c1d2f'
    self.title = '帮张三订明天深夜23:00后到上海的航班，并预订上海酒店凌晨入住'
    self.description = '帮张三订明天深夜23:00后到上海的航班，并预订上海酒店凌晨入住'
    self.timeout_seconds = 300
    
    def prepare
      @destination_city = '上海'
      @flight_date = Date.current + 1.day
      @min_departure_hour = 23
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 查找深夜航班（23:00后）
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= @min_departure_hour }
      
      # 查找上海的酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
      
      raise "未找到符合条件的深夜航班" if @available_flights.empty?
      raise "未找到上海的酒店" if @available_hotels.empty?
      
      # 入住日期应该是到达日期（可能是次日）
      sample_flight = @available_flights.first
      @check_in_date = sample_flight.arrival_time.to_date
      sample_hotel = @available_hotels.first
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。张三需要预订明天深夜23:00后到上海的航班，并预订上海酒店凌晨入住",
        description: "张三需要预订明天深夜23:00后到上海的航班，并预订上海酒店凌晨入住",
        scenario: "张三明天需要乘坐深夜航班到#{@destination_city}（起飞≥23:00），到达后直接凌晨入住酒店",
        requirements: {
          destination_city: @destination_city,
          flight_date: @flight_date,
          min_departure_hour: "≥23:00",
          check_in_date: @check_in_date,
          passenger: @expected_guest_name,
          purpose: '深夜航班凌晨入住'
        },
        available_flights_sample: {
          count: @available_flights.size,
          example: "#{sample_flight.flight_number}（#{sample_flight.departure_time.strftime('%H:%M')}起飞，#{sample_flight.arrival_time.strftime('%m月%d日 %H:%M')}到达）"
        },
        available_hotels_sample: {
          count: @available_hotels.size,
          example: "#{sample_hotel.name}（#{sample_hotel.city}）"
        }
      }
    end
    
    def verify
      add_assertion "创建了航班和酒店订单", weight: 15 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到到#{@destination_city}的航班订单"
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @flight_booking.nil? || @hotel_booking.nil?
      
      add_assertion "航班到达城市正确（#{@destination_city}）", weight: 10 do
        expect(@flight_booking.flight.destination_city).to eq(@destination_city),
          "到达城市错误。期望: #{@destination_city}, 实际: #{@flight_booking.flight.destination_city}"
      end
      
      add_assertion "航班出发日期正确（明天#{@flight_date}）", weight: 10 do
        expect(@flight_booking.flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（明天）, 实际: #{@flight_booking.flight.flight_date}"
      end
      
      add_assertion "航班起飞时间≥23:00", weight: 15 do
        hour = @flight_booking.flight.departure_time.hour
        expect(hour).to be >= @min_departure_hour,
          "起飞时间过早。期望: ≥#{@min_departure_hour}:00, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}"
      end
      
      add_assertion "酒店位于#{@destination_city}", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@destination_city),
          "酒店城市错误。期望: #{@destination_city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "酒店入住日期正确（凌晨到达应算前一天）", weight: 25 do
        arrival_time = @flight_booking.flight.arrival_time
        arrival_hour = arrival_time.hour
        
        # 如果是凌晨到达（0:00-6:00），入住日期应为航班出发日期（酒店按自然日计算）
        # 否则入住日期为到达日期
        if arrival_hour >= 0 && arrival_hour < 6
          expected_check_in_date = @flight_booking.flight.flight_date  # 航班出发日期
          expect(@hotel_booking.check_in_date).to eq(expected_check_in_date),
            "入住日期错误。航班凌晨#{arrival_time.strftime('%H:%M')}到达，入住应算前一天。期望: #{expected_check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        else
          expected_check_in_date = arrival_time.to_date
          expect(@hotel_booking.check_in_date).to eq(expected_check_in_date),
            "入住日期错误。期望: #{expected_check_in_date}（航班到达日期）, 实际: #{@hotel_booking.check_in_date}"
        end
      end
      
      add_assertion "乘客/入住人信息正确（张三）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_guest_name),
          "航班乘客姓名错误。期望: #{@expected_guest_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最便宜的深夜航班
      flight = @available_flights.min_by(&:price)
      arrival_time = flight.arrival_time
      arrival_hour = arrival_time.hour
      
      # 如果是凌晨到达（0:00-6:00），入住日期为航班出发日期（酒店按自然日计算）
      # 否则入住日期为到达日期
      if arrival_hour >= 0 && arrival_hour < 6
        check_in_date = flight.flight_date  # 出发日期
      else
        check_in_date = arrival_time.to_date  # 到达日期
      end
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @expected_guest_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 选择价格合理的酒店（过滤nil价格）
      valid_hotels = @available_hotels.select { |h| h.price.present? }
      raise "未找到有效价格的酒店" if valid_hotels.empty?
      
      hotel = valid_hotels.min_by(&:price)
      room = hotel.hotel_rooms.where(data_version: 0).where.not(price: nil).order(price: :asc).first
      raise "未找到酒店房间" unless room
      
      # 创建酒店订单（入住日期根据到达时间判断）
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: check_in_date,
        check_out_date: check_in_date + 1.day,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: room.price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        min_departure_hour: @min_departure_hour,
        check_in_date: @check_in_date.to_s,
        expected_guest_name: @expected_guest_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @min_departure_hour = data['min_departure_hour']
      @check_in_date = Date.parse(data['check_in_date'])
      @expected_guest_name = data['expected_guest_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
      @available_flights = Flight.where(
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).select { |f| f.departure_time.hour >= @min_departure_hour }
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).to_a
    end
  end
end
