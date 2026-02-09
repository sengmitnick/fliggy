# frozen_string_literal: true

require_relative '../base_validator'

# V129: 预订最便宜的航班+酒店组合（总价最低）
module V101V150
  class V129BookCheapestFlightAndHotelComboValidator < BaseValidator
  self.validator_id = 'v129_book_cheapest_flight_and_hotel_combo_validator'
  self.task_id = 'b74f2624-643d-4736-a48c-0aaf816eac67'
  self.title = '给王芳预订后天最便宜的航班+酒店组合（总价最低）'
  self.description = '帮王芳订后天从上海到深圳的航班和深圳酒店（1晚），要求航班+酒店总价最低'
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
