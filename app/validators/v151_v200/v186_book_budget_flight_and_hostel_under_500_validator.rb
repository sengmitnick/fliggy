# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例186: 给王芳预订明天北京到上海的预算航班和上海青旅/经济型酒店（总预算≤500元）
#
# 任务描述:
#   学生王芳需要预订明天从北京到上海的航班和青旅/经济型酒店，总预算不超过500元。
#   Agent需要搜索低价航班（≤300元）和低价住宿（≤200元），确保总价不超过预算，
#   帮助学生党实现经济实惠的出行。
#
# 业务流程（6个关键步骤）：
#   1. 搜索北京→上海的低价航班（明天出发，价格≤300元）
#   2. 搜索上海的低价住宿（青旅/经济型酒店，整晚房价格≤200元）
#   3. 计算航班+酒店总价，确保≤500元
#   4. 预订最便宜的航班
#   5. 预订最便宜的酒店（入住=航班到达日期，退房=入住+1天）
#   6. 确保航班和酒店的乘客/入住人信息一致（王芳）
#
# 复杂度分析（6个关键点）：
#   1. 需要筛选低价航班（价格≤300元，适合学生预算）
#   2. 需要筛选低价住宿（青旅/经济型酒店，整晚房≤200元）
#   3. 需要计算航班+酒店总价并满足预算约束（≤500元）
#   4. 需要在符合预算的选项中优选最便宜的组合
#   5. 需要确保只考虑整晚房（排除钟点房误导）
#   6. 需要确保航班和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索航班→搜索酒店→计算总价→验证预算→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了航班订单（北京→上海）（18分）
#   - 创建了酒店订单（18分）
#   - 航班价格合理（≤300元）（14分）
#   - 酒店价格合理（≤200元）（14分）
#   - 总价≤500元（18分）
#   - 酒店退房日期正确（3分）
#   - 航班乘客信息正确（王芳）（7分）
#   - 酒店入住人信息正确（王芳）（8分）
#
# API使用方法:
#   GET /api/tasks - 获取任务列表（包含本任务）
#   POST /api/tasks/:id/start - 创建训练会话（获取任务详情和data_version）
#   POST /api/verify/run - 提交验证结果（验证订单创建情况）
module V151V200
  class V186BookBudgetFlightAndHostelUnder500Validator < BaseValidator
    self.validator_id = 'v186_book_budget_flight_and_hostel_under_500_validator'
    self.task_id = '157ef268-c392-49fc-b869-c11412299bca'
    self.title = '给王芳预订明天北京到上海的预算航班和上海青旅/经济型酒店（总预算≤500元）'
    self.description = '帮学生王芳订明天从北京到上海的航班+青旅，总预算不超过500元'
    self.timeout_seconds = 300
  
    def prepare
      # 查找乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 定义出行信息和预算约束
      @departure_city = '北京'
      @arrival_city = '上海'
      @flight_date = Date.current + 1.day  # 明天
      @max_total_budget = 500.0  # 总预算上限
      @max_flight_price = 300.0  # 航班预算上限
      @max_hotel_price = 200.0   # 酒店预算上限
      
      # 查找低价航班（价格≤300元，适合学生预算）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.price <= @max_flight_price }
        .sort_by(&:price)  # 按价格升序排序
      
      expect(@available_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}低价航班（≤#{@max_flight_price.to_i}元）"
      
      # 查找低价酒店（整晚房价格≤200元，青旅/经济型酒店）
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
      
      # 按整晚房最低价排序（优选最便宜的住宿）
      @available_hotels.sort_by! do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end
      
      @available_hotels = @available_hotels.first(20)
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}低价酒店（整晚房≤#{@max_hotel_price.to_i}元）"
      
      # 计算酒店入住退房时间（入住=航班到达日期，退房=入住+1天）
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
      # 查找用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 创建航班订单（选择最便宜的航班，符合学生预算）
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
      
      # 创建酒店订单（选择最便宜的青旅/经济型酒店房间）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了航班订单 (18%)
      add_assertion "创建了航班订单（#{@departure_city}→#{@arrival_city}）", weight: 18 do
        # 查询航班订单（使用LIKE模糊匹配城市名称，兼容不同数据格式）
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where("flights.departure_city LIKE ? AND flights.destination_city LIKE ?", "%#{@departure_city}%", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单（#{@departure_city}→#{@arrival_city}）"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 创建了酒店订单 (18%)
      add_assertion "创建了酒店订单（#{@arrival_city}）", weight: 18 do
        # 查询酒店订单（使用LIKE模糊匹配城市名称）
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where("hotels.city LIKE ?", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 航班价格合理（≤300元，符合学生预算） (14%)
      add_assertion "航班价格合理（≤#{@max_flight_price.to_i}元）", weight: 14 do
        flight_price = @flight_booking.total_price
        expect(flight_price).to be <= @max_flight_price,
          "航班价格过高，超出学生预算。期望: ≤#{@max_flight_price.to_i}元, 实际: #{flight_price}元"
      end
      
      # 断言4: 酒店价格合理（≤200元，青旅/经济型酒店） (14%)
      add_assertion "酒店价格合理（≤#{@max_hotel_price.to_i}元）", weight: 14 do
        hotel_price = @hotel_booking.total_price
        expect(hotel_price).to be <= @max_hotel_price,
          "酒店价格过高，超出预算。期望: ≤#{@max_hotel_price.to_i}元（青旅/经济型酒店）, 实际: #{hotel_price}元"
      end
      
      # 断言5: 总价≤500元（核心预算约束） (18%)
      add_assertion "总价≤#{@max_total_budget.to_i}元（符合学生预算）", weight: 18 do
        total_price = @flight_booking.total_price + @hotel_booking.total_price
        expect(total_price).to be <= @max_total_budget,
          "总价超出学生预算。期望: ≤#{@max_total_budget.to_i}元, 实际: #{total_price}元（航班#{@flight_booking.total_price}元+酒店#{@hotel_booking.total_price}元）"
      end
      
      # 断言6: 酒店退房日期正确 (3%)
      add_assertion "酒店退房日期正确", weight: 3 do
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言7: 航班乘客信息正确 (7%)
      add_assertion "航班乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
      
      # 断言8: 酒店入住人信息正确 (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
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
        max_hotel_price: @max_hotel_price,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '王芳'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @max_total_budget = data['max_total_budget']
      @max_flight_price = data['max_flight_price']
      @max_hotel_price = data['max_hotel_price']
      
      # 重建可用航班列表（低价航班≤300元）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @flight_date, data_version: 0)
        .select { |f| f.price <= @max_flight_price }
        .sort_by(&:price)
      
      # 重建可用酒店列表（低价住宿，整晚房≤200元）
      @available_hotels = Hotel
        .joins(:hotel_rooms)
        .where("hotels.city LIKE ?", "%#{@arrival_city}%")
        .where("hotel_rooms.price <= ?", @max_hotel_price)
        .where("hotel_rooms.room_category = ?", 'overnight')
        .where(hotels: { data_version: 0 })
        .where(hotel_rooms: { data_version: 0 })
        .distinct
        .to_a
    end
  end
end
