# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例129: 帮王芳预订后天上海→深圳航班+深圳酒店（1晚），要求航班+酒店总价最低
#
# 任务描述:
#   王芳后天需要从上海前往深圳出差，需要预订航班和酒店各1晚。
#   由于预算有限，要求选择航班+酒店总价最低的组合方案。
#   Agent 需要创建1个航班订单和1个酒店订单，分别选择最便宜的航班和最便宜的酒店（整晚房型），使总价最低。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（王芳，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索上海→深圳航班（后天出发）
#   3. 按价格升序排序，找到最便宜的航班
#   4. 搜索深圳市区酒店
#   5. 筛选整晚房型（排除钟点房 room_category = 'overnight'）
#   6. 按房价升序排序，找到最便宜的房间
#   7. 创建航班订单（使用王芳的乘客信息）
#   8. 创建酒店订单（使用王芳的入住人信息，入住日期=航班日期，住1晚）
#
# 复杂度分析（9个关键点）：
#   1. 需要理解"总价最低"的优化目标：航班价格+酒店价格总和最小
#   2. 需要明确航班信息（上海→深圳，后天出发）
#   3. 需要使用受益人信息作为航班乘客和酒店入住人
#   4. 需要搜索并比较所有可用航班的价格，选择最低价航班
#   5. 需要明确酒店城市（深圳）和入住时间（航班到达当天）
#   6. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   7. 需要搜索并比较所有可用酒店房间的价格，选择最低价房间
#   8. 需要计算总价并验证是否达到最优（航班最低价+酒店最低价）
#   9. 需要理解"总价最低"不是"平均价格"，而是"总和最小"
#   ❌ 不能一次性提供所有信息：需要分别查询航班和酒店数据，对比价格，选择最优组合，分步骤创建订单。
#
# 评分标准（8项，总计100分）：
#   1. 创建了航班订单（20分）
#   2. 航班乘客信息正确（王芳的姓名和身份证号）（10分）
#   3. 航班城市和日期正确（上海→深圳，后天）（10分）
#   4. 创建了酒店订单（15分）
#   5. 酒店入住人信息正确（王芳的姓名和电话）（10分）
#   6. 酒店入住时间和时长正确（航班到达当天入住1晚）（10分）
#   7. 航班价格是最低价（10分）
#   8. 总价优化正确（航班+酒店总价最低，≤理论最低价的110%）（15分）
#
# 使用方法:
#   rake validator:simulate_single[v129_book_cheapest_flight_and_hotel_combo_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V129BookCheapestFlightAndHotelComboValidator < BaseValidator
  self.validator_id = 'v129_book_cheapest_flight_and_hotel_combo_validator'
  self.task_id = 'b74f2624-643d-4736-a48c-0aaf816eac67'
  self.title = '帮王芳预订后天上海→深圳航班+深圳酒店（1晚），要求航班+酒店总价最低'
  self.description = '帮王芳预订后天上海→深圳航班+深圳酒店（1晚），要求航班+酒店总价最低'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '上海'
    @arrival_city = '深圳'
    @flight_date = Date.current + 2.days
    @hotel_city = '深圳'
    @check_in_date = @flight_date
    @check_out_date = @check_in_date + 1.day

    # 获取受益人信息
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
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

    @cheapest_flight = @available_flights.first
    @cheapest_hotel = @available_hotels.first
    # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
    @cheapest_room = @cheapest_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
    raise "未找到符合条件的房间" if @cheapest_room.nil?
    
    @min_total_price = @cheapest_flight.price + @cheapest_room.price

    {
      task: "请给王芳预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班和#{@hotel_city}酒店（#{@check_in_date.strftime('%Y年%m月%d日')}入住1晚），要求选择航班+酒店总价最低的组合。",
      requirements: {
        beneficiary: '王芳',
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 1,
        optimization: 'min_total_price'
      },
      hint: "选择最便宜的航班和最便宜的酒店，使总价最低。理论最低总价: ¥#{@min_total_price}"
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

    add_assertion "创建了酒店订单", weight: 15 do
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

    add_assertion "酒店入住时间和时长正确", weight: 10 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date)
      expect(@hotel_booking.check_out_date).to eq(@check_out_date)
    end

    add_assertion "航班价格是最低价", weight: 10 do
      flight_price = @flight_booking.total_price
      cheapest_price = @cheapest_flight.price
      expect(flight_price).to eq(cheapest_price),
        "航班价格不是最低。期望: ¥#{cheapest_price}, 实际: ¥#{flight_price}"
    end

    add_assertion "总价优化正确（航班+酒店总价最低）", weight: 15 do
      total_price = @flight_booking.total_price + @hotel_booking.total_price
      expect(total_price).to be <= @min_total_price * 1.1,
        "总价未优化。期望: ≤¥#{(@min_total_price * 1.1).round(2)}, 实际: ¥#{total_price}"
    end
  end

  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    passenger = user.passengers.find_by!(name: '王芳', data_version: 0)

    flight = @cheapest_flight
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

    hotel = @cheapest_hotel
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
      min_total_price: @min_total_price,
      cheapest_room_id: @cheapest_room&.id,
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
    @min_total_price = data['min_total_price'].to_f
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

    @cheapest_flight = @available_flights.first
    @cheapest_hotel = @available_hotels.first
    # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
    @cheapest_room = if data['cheapest_room_id']
      HotelRoom.find_by(id: data['cheapest_room_id'])
    else
      @cheapest_hotel&.hotel_rooms&.where(data_version: 0, room_category: 'overnight')&.order(price: :asc)&.first
    end
  end
  end
end
