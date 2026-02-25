# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例180: 给张三预订周五晚航班和周末度假酒店套餐
#
# 任务描述:
#   用户需要预订周五晚上的航班，并预订周末度假酒店套餐
#
# 复杂度分析:
#   1. 需要识别周五日期
#   2. 需要筛选晚上的航班（18:00后）
#   3. 需要预订周末酒店套餐（周五到周日）
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 航班是周五晚上出发 (20分)
#   - 创建了酒店套餐订单 (20分)
#   - 酒店在到达城市 (20分)
#   - 酒店入住周期为周末（至少2晚） (20分)
module V151V200
  class V180BookFridayNightFlightAndWeekendPackageValidator < BaseValidator
    self.validator_id = 'v180_book_friday_night_flight_and_weekend_package_validator'
    self.task_id = '9331db0e-0f5f-43ca-85b4-8f2d4b62380b'
    self.title = '给张三预订周五晚航班和周末度假酒店套餐'
    self.description = '预订周五晚航班和周末度假酒店套餐'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '三亚'
      
      # 查找最近的周五
      @friday_date = Date.current + 1.day  # 明天
      until @friday_date.friday?
        @friday_date += 1.day
      end
      
      # 查找周五晚上的航班（18:00后）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @friday_date, data_version: 0)
        .select { |f| f.departure_time.hour >= 18 }
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}周五晚上的航班"
      
      # 查找三亚的酒店套餐（优先）或酒店
      @available_packages = HotelPackage
        .joins(:hotel)
        .where(hotels: { city: @arrival_city })
        .where(data_version: 0)
        .limit(10)
        .to_a
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_packages.any? || @available_hotels.any?).to be_truthy, "数据包缺少#{@arrival_city}的酒店或套餐"
      
      @hotel_checkin_date = @friday_date  # 周五入住
      @hotel_checkout_date = @friday_date + 2.days  # 周日退房
      
      {
        task: "请为#{@passenger.name}预订#{@friday_date.strftime('%Y年%m月%d日')}（#{(@friday_date - Date.current).to_i}天后，周五）从#{@departure_city}到#{@arrival_city}的晚上航班（18:00后），" \
              "并预订周末度假酒店套餐（周五到周日，2晚）",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @friday_date.to_s,
          flight_weekday: "周五",
          departure_time: "18:00后",
          hotel_location: @arrival_city,
          hotel_checkin: @hotel_checkin_date.to_s,
          hotel_checkout: @hotel_checkout_date.to_s,
          nights: 2
        },
        hint: "周五晚出发，周末度假放松，周日晚返回",
        statistics: {
          available_friday_flights: @available_flights.count,
          available_packages: @available_packages.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
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
      
      # 创建酒店套餐订单（如果有）或普通酒店订单
      if @available_packages.any?
        package = @available_packages.first
        HotelPackageOrder.create!(
          user: user,
          hotel_package: package,
          guest_name: @passenger.name,
          guest_phone: passenger.phone,
          check_in_date: @hotel_checkin_date,
          check_out_date: @hotel_checkout_date,
          guest_count: 2,
          total_price: package.price * 2,  # 2晚
          data_version: @data_version
        )
      else
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
          total_price: room.price * 2,  # 2晚
          data_version: @data_version
        )
      end
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
      
      # 断言2: 航班是周五晚上出发 (18%)
      add_assertion "航班是周五晚上出发", weight: 18 do
        flight_date = @flight_booking.flight.flight_date
        departure_hour = @flight_booking.flight.departure_time.hour
        
        is_friday = flight_date.friday?
        expect(is_friday).to be(true)
        unless is_friday
          raise RSpec::Expectations::ExpectationNotMetError, "不是周五。期望: 周五, 实际: #{flight_date.strftime('%A')}"
        end
        expect(departure_hour).to be >= 18
      end
      
      # 断言3: 创建了酒店套餐或酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
        @package_order = HotelPackageOrder
          .joins(hotel_package: :hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@package_order || @hotel_booking).not_to be_nil, "未找到酒店订单或套餐订单"
      end
      
      return if @package_order.nil? && @hotel_booking.nil?
      
      # 断言4: 酒店在到达城市 (15%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 15 do
        if @package_order
          hotel = @package_order.hotel_package.hotel
          expect(hotel.city).to include(@arrival_city),
            "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
        else
          hotel = @hotel_booking.hotel
          expect(hotel.city).to include(@arrival_city),
            "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
        end
      end
      
      # 断言5: 酒店入住周期为周末（至少2晚） (17%)
      add_assertion "酒店入住周期为周末（至少2晚）", weight: 17 do
        checkin = @package_order ? @package_order.check_in_date : @hotel_booking.check_in_date
        checkout = @package_order ? @package_order.check_out_date : @hotel_booking.check_out_date
        nights = (checkout - checkin).to_i
        
        expect(checkin).to eq(@friday_date),
          "入住日期错误。期望: #{@friday_date}（周五）, 实际: #{checkin}"
        expect(nights).to be >= 2,
          "住宿天数不足。期望: 至少2晚, 实际: #{nights}晚"
      end
    
      # 断言6: 航班乘客信息正确（王芳） (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "航班联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（王芳） (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        if @package_order
          expect(@package_order.guest_name).to eq(@expected_passenger_name),
            "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@package_order.guest_name}"
          expect(@package_order.guest_phone).to eq(@expected_phone),
            "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@package_order.guest_phone}"
        else
          expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
            "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
          expect(@hotel_booking.guest_phone).to eq(@expected_phone),
            "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
        end
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        friday_date: @friday_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @friday_date = Date.parse(data['friday_date']) if data['friday_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用航班、酒店和套餐（用于simulate阶段）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @friday_date, data_version: 0)
        .select { |f| f.departure_time.hour >= 18 }
      
      @available_packages = HotelPackage
        .joins(:hotel)
        .where(hotels: { city: @arrival_city })
        .where(data_version: 0)
        .limit(10)
        .to_a
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end