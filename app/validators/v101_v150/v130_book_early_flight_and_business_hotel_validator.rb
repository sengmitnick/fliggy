# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例130: 帮刘强预订明天北京→上海早班航班（9点前）+上海市区商务酒店（3星级以上，明天入住4晚）
#
# 任务描述:
#   刘强明天早上需要从北京前往上海参加商务会议，希望尽早到达。
#   需要预订明天早上9点前起飞的航班，以及上海市区的3星级以上商务酒店，明天入住，连住4晚。
#   Agent 需要创建1个航班订单和1个酒店订单，确保航班起飞时间在9点前，酒店星级≥3星，住宿时长为4晚。
#
# 业务流程（9个关键步骤）：
#   1. 明确受益人信息（刘强，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索北京→上海航班（明天出发）
#   3. 筛选早班航班（起飞时间<9:00）
#   4. 创建航班订单（使用刘强的乘客信息）
#   5. 搜索上海市区酒店
#   6. 筛选商务酒店（星级≥3星）
#   7. 筛选整晚房型（排除钟点房 room_category = 'overnight'）
#   8. 计算酒店总价（房价×4晚）
#   9. 创建酒店订单（使用刘强的入住人信息，明天入住，住4晚）
#
# 复杂度分析（9个关键点）：
#   1. 需要理解商务出行场景：早班航班+商务酒店组合
#   2. 需要筛选早班航班（起飞时间<9:00），确保尽早到达
#   3. 需要明确航班信息（北京→上海，明天出发）
#   4. 需要使用受益人信息作为航班乘客和酒店入住人
#   5. 需要筛选商务酒店（星级≥3星），满足商务出行标准
#   6. 需要明确酒店城市（上海）和入住时间（航班到达当天）
#   7. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   8. 需要理解"连住4晚"的时间逻辑（入住日期=航班日期，退房日期=入住+4天）
#   9. 需要计算酒店总价（房价×4晚）
#   ❌ 不能一次性提供所有信息：需要分别筛选早班航班（时间约束）和商务酒店（星级约束），分步骤创建订单。
#
# 评分标准（8项，总计100分）：
#   1. 创建了航班订单（20分）
#   2. 航班乘客信息正确（刘强的姓名和身份证号）（10分）
#   3. 航班城市和日期正确（北京→上海，明天）（10分）
#   4. 航班是早班（9点前起飞）（10分）
#   5. 创建了酒店订单（20分）
#   6. 酒店入住人信息正确（刘强的姓名和电话）（10分）
#   7. 酒店是商务酒店（3星级以上）（10分）
#   8. 酒店入住时间和时长正确（明天入住4晚）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v130_book_early_flight_and_business_hotel_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V130BookEarlyFlightAndBusinessHotelValidator < BaseValidator
  self.validator_id = 'v130_book_early_flight_and_business_hotel_validator'
  self.task_id = 'b27293c5-2a36-4bc9-aac4-b858aae91ac8'
  self.title = '帮刘强预订明天北京→上海早班航班（9点前）+上海市区商务酒店（3星级以上，明天入住4晚）'
  self.description = '帮刘强预订明天北京→上海早班航班（9点前）+上海市区商务酒店（3星级以上，明天入住4晚）'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '北京'
    @arrival_city = '上海'
    @flight_date = Date.current + 1.day
    @hotel_city = '上海'
    @min_star_level = 3
    @check_in_date = @flight_date
    @check_out_date = @check_in_date + 4.days

    # 获取受益人信息
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
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
    
    @available_flights = all_flights_on_route.select { |f| f.departure_time.hour < 9 }
    
    raise "未找到符合条件的航班" if @available_flights.empty?

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).where('star_level >= ?', @min_star_level).order(price: :asc)

    raise "未找到符合条件的航班" if @available_flights.empty?
    raise "未找到符合条件的酒店" if @available_hotels.empty?

    {
      task: "请给刘强预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）早上9点前从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}市区3星级以上商务酒店，#{@check_in_date.strftime('%Y年%m月%d日')}（明天）入住，住4晚。",
      requirements: {
        beneficiary: '刘强',
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        departure_time_before: '09:00',
        hotel_city: @hotel_city,
        min_star_level: @min_star_level,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 4
      },
      hint: "预订早班航班（9点前起飞），选择3星级以上商务酒店，连住4晚。"
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

    add_assertion "航班乘客信息正确（刘强）", weight: 10 do
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

    add_assertion "航班是早班（9点前起飞）", weight: 10 do
      hour = @flight_booking.flight.departure_time.hour
      expect(hour).to be < 9,
        "航班不是早班。期望: 9点前起飞, 实际: #{@flight_booking.flight.departure_time.strftime('%H:%M')}起飞"
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

    add_assertion "酒店入住人信息正确（刘强）", weight: 10 do
      expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
        "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
      expect(@hotel_booking.guest_phone).to eq(@expected_phone),
        "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
    end

    add_assertion "酒店是商务酒店（3星级以上）", weight: 10 do
      star_level = @hotel_booking.hotel.star_level
      expect(star_level).to be >= @min_star_level,
        "酒店星级不足。期望: ≥#{@min_star_level}星, 实际: #{star_level}星"
    end

    add_assertion "酒店入住时间和时长正确", weight: 10 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（明天，航班当天）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（住4晚）, 实际: #{@hotel_booking.check_out_date}"
    end
  end

  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = user.passengers.find_by!(name: '刘强', data_version: 0)

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
      total_price: room.price * 4,
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
      min_star_level: @min_star_level,
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
    @min_star_level = data['min_star_level']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @expected_passenger_name = data['expected_passenger_name']
    @expected_passenger_id_number = data['expected_passenger_id_number']
    @expected_phone = data['expected_phone']

    all_flights_on_route = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    )
    
    @available_flights = all_flights_on_route.select { |f| f.departure_time.hour < 9 }

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).where('star_level >= ?', @min_star_level).order(price: :asc)
  end
  end
end
