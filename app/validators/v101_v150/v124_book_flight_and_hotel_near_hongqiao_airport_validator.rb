# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例124: 帮李四预订3天后上海→深圳航班+宝安机场附近酒店（当天入住2晚）
#
# 任务描述:
#   李四3天后需要从上海飞往深圳，并在深圳宝安国际机场附近住宿2晚。
#   Agent 需要创建2个订单：航班订单（上海→深圳，3天后）和酒店订单（宝安机场附近，航班当天入住，住2晚）。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（李四）
#   2. 查询3天后上海→深圳的航班
#   3. 选择航班并创建航班订单
#   4. 明确酒店城市（深圳）
#   5. 明确酒店位置要求（宝安国际机场附近）
#   6. 明确入住日期（航班当天）和时长（2晚）
#   7. 查询符合条件的酒店
#   8. 创建酒店订单
#
# 复杂度分析（8个关键点）：
#   1. 需要理解组合预订：航班+酒店两个独立订单
#   2. 需要明确航班信息（上海→深圳，3天后）
#   3. 需要使用受益人信息作为航班乘客和酒店入住人
#   4. 需要理解"宝安国际机场附近"的地理位置要求
#   5. 需要明确酒店城市（深圳）
#   6. 需要计算入住日期（航班当天）和退房日期（住2晚）
#   7. 需要分别完成航班预订和酒店预订两个流程
#   8. 需要确保航班日期和酒店入住日期匹配
#   ❌ 不能一次性提供：需要先预订航班→确认航班日期→根据航班日期确定酒店入住日期→预订宝安机场附近酒店
#
# 评分标准（8项，总计100分）：
#   - 创建了航班订单（20分）
#   - 航班乘客信息正确（李四）（10分）
#   - 航班城市正确（上海→深圳）（10分）
#   - 航班日期正确（3天后）（10分）
#   - 创建了酒店订单（20分）
#   - 酒店入住人信息正确（李四）（10分）
#   - 酒店城市正确（深圳）（10分）
#   - 酒店入住日期和时长正确（航班当天入住，住2晚）（10分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v124_book_flight_and_hotel_near_hongqiao_airport_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V124BookFlightAndHotelNearHongqiaoAirportValidator < BaseValidator
  self.validator_id = 'v124_book_flight_and_hotel_near_hongqiao_airport_validator'
  self.task_id = 'c5d6e7f8-9a0b-1c2d-3e4f-5a6b7c8d9e0f'
  self.title = '帮李四订3天后从上海飞深圳的航班，并在宝安国际机场附近订酒店（航班当天入住2晚）'
  self.description = '帮李四订3天后从上海飞深圳的航班，并在宝安国际机场附近订酒店（航班当天入住2晚）'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '上海'
    @arrival_city = '深圳'
    @flight_date = Date.current + 3.days
    @hotel_city = '深圳'
    @check_in_date = @flight_date
    @check_out_date = @check_in_date + 2.days

    # 获取受益人信息
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
    @expected_passenger_name = @passenger.name
    @expected_passenger_id_number = @passenger.id_number
    @expected_phone = @passenger.phone

    @available_flights = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    ).order(price: :asc)

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).order(price: :asc)

    raise "未找到符合条件的航班" if @available_flights.empty?
    raise "未找到符合条件的酒店" if @available_hotels.empty?

    {
      task: "请给李四预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}宝安国际机场附近的酒店，#{@check_in_date.strftime('%Y年%m月%d日')}入住，住2晚。",
      requirements: {
        beneficiary: '李四',
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 2
      },
      hint: "需要预订航班和酒店两个订单。酒店要在#{@hotel_city}，入住日期是航班到达当天，住2晚。"
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

    add_assertion "航班乘客信息正确（李四）", weight: 10 do
      expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
        "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
      expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id_number),
        "身份证号错误。期望: #{@expected_passenger_id_number}, 实际: #{@flight_booking.passenger_id_number}"
    end

    add_assertion "航班城市正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
      expect(@flight_booking.flight.departure_city).to eq(@departure_city),
        "出发城市错误。期望: #{@departure_city}, 实际: #{@flight_booking.flight.departure_city}"
      expect(@flight_booking.flight.destination_city).to eq(@arrival_city),
        "到达城市错误。期望: #{@arrival_city}, 实际: #{@flight_booking.flight.destination_city}"
    end

    add_assertion "航班日期正确（#{@flight_date}）", weight: 10 do
      expect(@flight_booking.flight.flight_date).to eq(@flight_date),
        "航班日期错误。期望: #{@flight_date}（3天后）, 实际: #{@flight_booking.flight.flight_date}"
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

    add_assertion "酒店入住人信息正确（李四）", weight: 10 do
      expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
        "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
      expect(@hotel_booking.guest_phone).to eq(@expected_phone),
        "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
    end

    add_assertion "酒店城市正确（#{@hotel_city}）", weight: 10 do
      expect(@hotel_booking.hotel.city).to eq(@hotel_city),
        "酒店城市错误。期望: #{@hotel_city}, 实际: #{@hotel_booking.hotel.city}"
    end

    add_assertion "酒店入住日期和时长正确", weight: 10 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（住2晚）, 实际: #{@hotel_booking.check_out_date}"
    end
  end

  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = user.passengers.find_by!(name: '李四', data_version: 0)

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
      total_price: room.price * 2,
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
    @expected_passenger_name = data['expected_passenger_name']
    @expected_passenger_id_number = data['expected_passenger_id_number']
    @expected_phone = data['expected_phone']

    @available_flights = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    ).order(price: :asc)

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).order(price: :asc)
  end
  end
end
