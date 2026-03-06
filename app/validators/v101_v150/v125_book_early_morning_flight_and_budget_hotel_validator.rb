# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例125: 帮王芳预订明天北京→上海早班航班（8点前）+首都机场附近经济型酒店（今晚入住，预算≤300元）
#
# 任务描述:
#   王芳明天需要搭乘早班航班（8点前起飞）从北京飞往上海，为了方便赶早班机，需要今晚入住首都机场附近的经济型酒店。
#   Agent 需要创建2个订单：航班订单（北京→上海，明天8点前起飞）和酒店订单（首都机场附近，今晚入住1晚，预算300元以下）。
#
# 业务流程（9个关键步骤）：
#   1. 明确受益人信息（王芳）
#   2. 查询明天北京→上海的航班，筛选8点前起飞的早班航班
#   3. 选择早班航班并创建航班订单
#   4. 明确酒店城市（北京）
#   5. 明确酒店位置要求（首都机场附近）
#   6. 明确酒店预算（300元以下的经济型酒店）
#   7. 明确入住日期（今晚）和退房日期（明天，航班当天）
#   8. 查询符合条件的经济型酒店
#   9. 创建酒店订单
#
# 复杂度分析（9个关键点）：
#   1. 需要理解组合预订：航班+酒店两个独立订单
#   2. 需要筛选早班航班（起飞时间<8点）
#   3. 需要理解"提前一晚入住"的时间逻辑（今晚入住，明天航班当天退房）
#   4. 需要使用受益人信息作为航班乘客和酒店入住人
#   5. 需要理解"首都机场附近"的地理位置要求
#   6. 需要筛选经济型酒店（价格<300元）
#   7. 需要明确酒店城市（北京，不是上海）
#   8. 需要分别完成航班预订和酒店预订两个流程
#   9. 需要确保酒店退房日期与航班日期匹配
#   ❌ 不能一次性提供：需要先查询早班航班→确认航班日期→根据航班日期确定提前一晚入住日期→筛选预算内经济型酒店→预订机场附近酒店
#
# 评分标准（8项，总计100分）：
#   - 创建了航班订单（20分）
#   - 航班乘客信息正确（王芳）（10分）
#   - 航班城市和日期正确（北京→上海，明天）（10分）
#   - 航班是早班（8点前起飞）（10分）
#   - 创建了酒店订单（20分）
#   - 酒店入住人信息正确（王芳）（10分）
#   - 酒店是经济型（300元以下）（10分）
#   - 酒店入住时间正确（今晚入住，明天退房）（10分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v125_book_early_morning_flight_and_budget_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V125BookEarlyMorningFlightAndBudgetHotelValidator < BaseValidator
  self.validator_id = 'v125_book_early_morning_flight_and_budget_hotel_validator'
  self.task_id = '661e90ec-e0f0-4519-a868-44e3d3e327c9'
  self.title = '帮王芳预订明天北京→上海早班航班（8点前）+首都机场附近经济型酒店（今晚入住，预算≤300元）'
  self.description = '帮王芳预订明天北京→上海早班航班（8点前）+首都机场附近经济型酒店（今晚入住，预算≤300元）'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '北京'
    @arrival_city = '上海'
    @flight_date = Date.current + 1.day
    @hotel_city = '北京'
    @check_in_date = Date.current
    @check_out_date = @flight_date
    @max_hotel_price = 300

    # 获取受益人信息
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
    @expected_passenger_name = @passenger.name
    @expected_passenger_id_number = @passenger.id_number
    @expected_phone = @passenger.phone

    # 查找早班航班（Ruby筛选）
    all_flights_on_route = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    )
    
    @available_flights = all_flights_on_route.select { |f| f.departure_time.hour < 8 }
    
    raise "未找到符合条件的航班" if @available_flights.empty?

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).where('price < ?', @max_hotel_price).order(price: :asc)

    raise "未找到符合条件的航班" if @available_flights.empty?
    raise "未找到符合条件的酒店" if @available_hotels.empty?

    {
      task: "请给王芳预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）早上8点前从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}首都机场附近的经济型酒店（300元以下），#{@check_in_date.strftime('%Y年%m月%d日')}（今晚）入住，住1晚。",
      requirements: {
        beneficiary: '王芳',
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        departure_time_before: '08:00',
        hotel_city: @hotel_city,
        hotel_max_price: @max_hotel_price,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 1
      },
      hint: "因为是早班航班，需要提前一晚入住机场附近的酒店。选择经济型酒店，价格在300元以下。"
    }
  end

  def verify
    add_assertion "创建了航班订单", weight: 20 do
      all_flight_bookings = Booking
        .joins(:flight)
        .includes(:flight)
        .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a

      @flight_booking = all_flight_bookings.first
      expect(@flight_booking).not_to be_nil, "未找到航班订单"
    end

    return if @flight_booking.nil?

    add_assertion "航班乘客信息正确（王芳）", weight: 10 do
      expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
        "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
      expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id_number),
        "身份证号错误。期望: #{@expected_passenger_id_number}, 实际: #{@flight_booking.passenger_id_number}"
    end

    add_assertion "航班城市和日期正确", weight: 10 do
      expect(@flight_booking.flight.departure_city).to eq(@departure_city)
      expect(@flight_booking.flight.destination_city).to eq(@arrival_city)
      expect(@flight_booking.flight.flight_date).to eq(@flight_date)
    end

    add_assertion "航班是早班（8点前起飞）", weight: 10 do
      hour = @flight_booking.flight.departure_time.hour
      expect(hour).to be < 8,
        "航班不是早班。期望: 8点前起飞, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}起飞"
    end

    add_assertion "创建了酒店订单", weight: 20 do
      all_hotel_bookings = HotelBooking
        .joins(:hotel)
        .includes(:hotel)
        .where(hotels: { city: @hotel_city })
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a

      @hotel_booking = all_hotel_bookings.first
      expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
    end

    return if @hotel_booking.nil?

    add_assertion "酒店入住人信息正确（王芳）", weight: 10 do
      expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
        "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
      expect(@hotel_booking.guest_phone).to eq(@expected_phone),
        "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
    end

    add_assertion "酒店是经济型（300元以下）", weight: 10 do
      hotel_price = @hotel_booking.hotel.price
      expect(hotel_price).to be < @max_hotel_price,
        "酒店价格超出预算。期望: <¥#{@max_hotel_price}, 实际: ¥#{hotel_price}"
    end

    add_assertion "酒店入住时间正确（提前一晚）", weight: 10 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（今晚，航班前一晚）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（明天，航班当天）, 实际: #{@hotel_booking.check_out_date}"
    end
  end

  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = user.passengers.find_by!(name: '王芳', data_version: 0)

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

    hotel = @available_hotels.first
    # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
    room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
    HotelBooking.create!(
      user: user,
      hotel: hotel,
      hotel_room_id: room.id,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
      guest_name: passenger.name,
      guest_phone: passenger.phone,
      payment_method: '花呗',
      total_price: room.price,
      data_version: @data_version
    )
  end

  private

  def execution_state_data
    {
      departure_city: @departure_city,
      arrival_city: @arrival_city,
      flight_date: @flight_date.to_s,
      hotel_city: @hotel_city,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      max_hotel_price: @max_hotel_price,
      expected_passenger_name: @expected_passenger_name,
      expected_passenger_id_number: @expected_passenger_id_number,
      expected_phone: @expected_phone
    }
  end

  def restore_from_state(data)
    @departure_city = data['departure_city']
    @arrival_city = data['arrival_city']
    @flight_date = Date.parse(data['flight_date'])
    @hotel_city = data['hotel_city']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @max_hotel_price = data['max_hotel_price']
    @expected_passenger_name = data['expected_passenger_name']
    @expected_passenger_id_number = data['expected_passenger_id_number']
    @expected_phone = data['expected_phone']

    all_flights_on_route = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    )
    
    @available_flights = all_flights_on_route.select { |f| f.departure_time.hour < 8 }

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).where('price < ?', @max_hotel_price).order(price: :asc)
  end
  end
end
