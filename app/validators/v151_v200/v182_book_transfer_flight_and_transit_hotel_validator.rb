# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例182: 给张三预订中转航班和中转城市酒店休息
#
# 任务描述:
#   用户需要预订中转航班（间隔>6小时），并在中转城市预订酒店休息
#
# 复杂度分析:
#   1. 需要查找中转航班组合（间隔>6小时）
#   2. 需要识别中转城市
#   3. 需要预订中转城市酒店（钟点房或短期入住）
#   4. 验证酒店入住时间在中转间隔内
#
# 评分标准:
#   - 创建了2个航班订单（出发+中转） (20分)
#   - 中转间隔超过6小时 (20分)
#   - 创建了中转城市酒店订单 (20分)
#   - 酒店在中转城市 (20分)
#   - 酒店入住时间在中转间隔内 (20分)
module V151V200
  class V182BookTransferFlightAndTransitHotelValidator < BaseValidator
    self.validator_id = 'v182_book_transfer_flight_and_transit_hotel_validator'
    self.task_id = '9aedf66b-ff40-41d2-9ff5-3e63982462a1'
    self.title = '给张三预订中转航班和中转城市酒店休息'
    self.description = '预订中转航班和中转城市酒店休息'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @transit_city = '上海'
      @final_city = '深圳'
      @travel_date = Date.current + 1.day  # 明天
      
      # 查找第一段航班（北京->上海）
      @first_flights = Flight
        .where(departure_city: @departure_city, destination_city: @transit_city, flight_date: @travel_date, data_version: 0)
        .to_a
      
      expect(@first_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@transit_city}的航班"
      
      # 查找第二段航班（上海->深圳），要求时间间隔>6小时
      @transit_combinations = []
      @first_flights.each do |first_flight|
        Flight.where(departure_city: @transit_city, destination_city: @final_city, data_version: 0).each do |second_flight|
          # 计算时间间隔
          interval_hours = (second_flight.departure_time - first_flight.arrival_time) / 3600.0
          
          if interval_hours > 6 && interval_hours < 24
            @transit_combinations << {
              first: first_flight,
              second: second_flight,
              interval_hours: interval_hours
            }
          end
        end
      end
      
      expect(@transit_combinations).not_to be_empty, "数据包缺少符合条件的中转航班组合（间隔>6小时）"
      
      # 查找中转城市的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@transit_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@transit_city}的酒店"
      
      @selected_combo = @transit_combinations.first
      @hotel_checkin_date = @selected_combo[:first].arrival_time.to_date
      @hotel_checkout_date = @selected_combo[:second].departure_time.to_date
      
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%Y年%m月%d日')}（#{(@travel_date - Date.current).to_i}天后）从#{@departure_city}经#{@transit_city}中转到#{@final_city}的航班，" \
              "要求中转时间超过6小时，并在#{@transit_city}预订酒店休息",
        requirements: {
          departure_city: @departure_city,
          transit_city: @transit_city,
          final_city: @final_city,
          travel_date: @travel_date.to_s,
          transfer_interval: ">6小时",
          hotel_location: @transit_city
        },
        hint: "中转时间较长，可以在机场附近酒店休息，避免在机场等待",
        statistics: {
          available_combinations: @transit_combinations.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      
      # 创建第一段航班订单
      first_flight = @selected_combo[:first]
      Booking.create!(
        user: user,
        flight: first_flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: first_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建第二段航班订单
      second_flight = @selected_combo[:second]
      Booking.create!(
        user: user,
        flight: second_flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        total_price: second_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建中转城市酒店订单
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date == @hotel_checkin_date ? @hotel_checkout_date + 1.day : @hotel_checkout_date,
        guest_name: @passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了2个航班订单 (20%)
      add_assertion "创建了2个航班订单（#{@departure_city}→#{@transit_city}→#{@final_city}）", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(data_version: @data_version)
          .order(:created_at)
          .to_a
        
        @first_booking = all_bookings.find { |b| b.flight.departure_city == @departure_city && b.flight.destination_city == @transit_city }
        @second_booking = all_bookings.find { |b| b.flight.departure_city == @transit_city && b.flight.destination_city == @final_city }
        
        expect(@first_booking).not_to be_nil, "未找到第一段航班订单（#{@departure_city}→#{@transit_city}）"
        expect(@second_booking).not_to be_nil, "未找到第二段航班订单（#{@transit_city}→#{@final_city}）"
      end
      
      return if @first_booking.nil? || @second_booking.nil?
      
      # 断言2: 中转间隔超过6小时 (18%)
      add_assertion "中转间隔超过6小时", weight: 18 do
        interval_hours = (@second_booking.flight.departure_time - @first_booking.flight.arrival_time) / 3600.0
        expect(interval_hours).to be > 6,
          "中转间隔不足。期望: >6小时, 实际: #{interval_hours.round(1)}小时"
      end
      
      # 断言3: 创建了中转城市酒店订单 (15%)
      add_assertion "创建了中转城市酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @transit_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到中转城市酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店在中转城市 (15%)
      add_assertion "酒店位置正确（#{@transit_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@transit_city),
          "酒店城市错误。期望: #{@transit_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住时间在中转间隔内 (17%)
      add_assertion "酒店入住时间在中转间隔内", weight: 17 do
        arrival_date = @first_booking.flight.arrival_time.to_date
        departure_date = @second_booking.flight.departure_time.to_date
        
        # 入住日期应该在第一段航班到达当天或之后，第二段航班出发当天或之前
        expect(@hotel_booking.check_in_date).to be >= arrival_date,
          "入住日期过早。期望: >= #{arrival_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_in_date).to be <= departure_date,
          "入住日期过晚。期望: <= #{departure_date}, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言6: 航班乘客信息正确（陈静） (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        # 验证第一段航班
        expect(@first_booking.passenger_name).to eq(@expected_passenger_name),
          "第一段航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@first_booking.passenger_name}"
        expect(@first_booking.contact_phone).to eq(@expected_phone),
          "第一段航班联系电话错误。期望: #{@expected_phone}, 实际: #{@first_booking.contact_phone}"
        
        # 验证第二段航班
        expect(@second_booking.passenger_name).to eq(@expected_passenger_name),
          "第二段航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@second_booking.passenger_name}"
        expect(@second_booking.contact_phone).to eq(@expected_phone),
          "第二段航班联系电话错误。期望: #{@expected_phone}, 实际: #{@second_booking.contact_phone}"
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
        transit_city: @transit_city,
        final_city: @final_city,
        travel_date: @travel_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @transit_city = data['transit_city']
      @final_city = data['final_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用航班和酒店（用于simulate阶段）
      @first_flights = Flight
        .where(departure_city: @departure_city, destination_city: @transit_city, flight_date: @travel_date, data_version: 0)
        .to_a
      
      @transit_combinations = []
      @first_flights.each do |first_flight|
        Flight.where(departure_city: @transit_city, destination_city: @final_city, data_version: 0).each do |second_flight|
          interval_hours = (second_flight.departure_time - first_flight.arrival_time) / 3600.0
          if interval_hours > 6 && interval_hours < 24
            @transit_combinations << {
              first: first_flight,
              second: second_flight,
              interval_hours: interval_hours
            }
          end
        end
      end
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@transit_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      @selected_combo = @transit_combinations.first if @transit_combinations.any?
    end
  end
end