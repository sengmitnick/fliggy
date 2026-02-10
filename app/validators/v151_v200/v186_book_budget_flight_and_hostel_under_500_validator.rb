# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例186: 预订预算航班和青旅组合（总预算≤500元）
#
# 任务描述:
#   学生出行，需要预订航班+青旅，总预算≤500元
#
# 复杂度分析:
#   1. 需要筛选低价航班
#   2. 需要筛选低价青旅/经济型酒店
#   3. 需要计算总价并满足预算约束
#   4. 验证总价≤500元
#
# 评分标准:
#   - 创建了航班订单 (20分)
#   - 创建了酒店订单 (20分)
#   - 航班价格合理（≤300元） (20分)
#   - 酒店价格合理（≤200元） (20分)
#   - 总价≤500元 (20分)
module V151V200
  class V186BookBudgetFlightAndHostelUnder500Validator < BaseValidator
    self.validator_id = 'v186_book_budget_flight_and_hostel_under_500_validator'
    self.task_id = '157ef268-c392-49fc-b869-c11412299bca'
    self.title = '给王芳预订明天北京到上海的预算航班和青旅（总预算≤500元）'
    self.description = '帮学生王芳订明天从北京到上海的航班+青旅，总预算不超过500元'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 1.day  # 明天
      @max_total_budget = 500.0
      @max_flight_price = 300.0
      @max_hotel_price = 200.0
      
      # 查找低价航班（≤300元）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.price <= @max_flight_price }
        .sort_by(&:price)
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}低价航班（≤#{@max_flight_price}元）"
      
      # 查找低价酒店（≤200元）
      # CRITICAL: 只选择拥有≤200元整晚房的酒店，避免钟点房误导
      @available_hotels = Hotel
        .joins(:hotel_rooms)
        .where("hotels.city LIKE ?", "%#{@arrival_city}%")
        .where("hotel_rooms.price <= ?", @max_hotel_price)
        .where("hotel_rooms.room_category = ?", 'overnight')  # 只考虑整晚房
        .where(hotels: { data_version: 0 })
        .where(hotel_rooms: { data_version: 0 })
        .distinct
        .to_a
      
      # 按整晚房最低价排序
      @available_hotels.sort_by! do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end
      
      @available_hotels = @available_hotels.first(20)
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}低价酒店（≤#{@max_hotel_price}元）"
      
      @hotel_checkin_date = @flight_date
      @hotel_checkout_date = @flight_date + 1.day
      
      {
        task: "请为#{@passenger.name}预订#{@flight_date.strftime('%Y年%m月%d日')}（#{(@flight_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的低价航班和青旅/经济型酒店，" \
              "总预算≤#{@max_total_budget.to_i}元",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date.to_s,
          max_budget: @max_total_budget,
          hotel_checkin: @hotel_checkin_date.to_s,
          accommodation_type: "青旅/经济型酒店"
        },
        hint: "学生党预算有限，选择经济实惠的组合",
        statistics: {
          available_budget_flights: @available_flights.count,
          available_budget_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 创建航班订单（选最便宜的）
      flight = @available_flights.first
      flight_booking = Booking.create!(
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
      
      # 创建酒店订单（选最便宜的房间）
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
    end
  
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单", weight: 20 do
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 航班价格合理（≤300元） (15%)
      add_assertion "航班价格合理（≤#{@max_flight_price.to_i}元）", weight: 15 do
        flight_price = @flight_booking.total_price
        expect(flight_price).to be <= @max_flight_price,
          "航班价格过高。期望: ≤#{@max_flight_price.to_i}元, 实际: #{flight_price}元"
      end
      
      # 断言4: 酒店价格合理（≤200元） (15%)
      add_assertion "酒店价格合理（≤#{@max_hotel_price.to_i}元）", weight: 15 do
        hotel_price = @hotel_booking.total_price
        expect(hotel_price).to be <= @max_hotel_price,
          "酒店价格过高。期望: ≤#{@max_hotel_price.to_i}元, 实际: #{hotel_price}元"
      end
      
      # 断言5: 总价≤500元 (25%)
      add_assertion "总价≤#{@max_total_budget.to_i}元", weight: 25 do
        total_price = @flight_booking.total_price + @hotel_booking.total_price
        expect(total_price).to be <= @max_total_budget,
          "总价超出预算。期望: ≤#{@max_total_budget.to_i}元, 实际: #{total_price}元（航班#{@flight_booking.total_price}+酒店#{@hotel_booking.total_price}）"
      end
      
      # 断言6: 酒店退房日期正确 (5%)
      add_assertion "酒店退房日期正确", weight: 5 do
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
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
        max_total_budget: @max_total_budget,
        max_flight_price: @max_flight_price,
        max_hotel_price: @max_hotel_price
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @max_total_budget = data['max_total_budget']
      @max_flight_price = data['max_flight_price']
      @max_hotel_price = data['max_hotel_price']
    end
  end
end
