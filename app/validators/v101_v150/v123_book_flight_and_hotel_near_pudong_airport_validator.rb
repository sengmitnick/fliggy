# frozen_string_literal: true

require_relative '../base_validator'

# V123: 预订后天北京→上海航班+上海浦东机场附近酒店
module V101V150
  class V123BookFlightAndHotelNearPudongAirportValidator < BaseValidator
  self.validator_id = 'v123_book_flight_and_hotel_near_pudong_airport_validator'
  self.task_id = 'b3c4d5e6-7a8b-9c0d-1e2f-3a4b5c6d7e8f'
  self.title = '预订后天北京→上海航班+上海浦东机场附近酒店'
  self.description = '预订后天从北京到上海的航班，并预订上海浦东国际机场附近的酒店（当天入住1晚）'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '北京'
    @arrival_city = '上海'
    @flight_date = Date.current + 2.days
    @hotel_city = '上海'
    @check_in_date = @flight_date
    @check_out_date = @check_in_date + 1.day

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
      task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}浦东国际机场附近的酒店，#{@check_in_date.strftime('%Y年%m月%d日')}入住，住1晚。",
      requirements: {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 1
      },
      hint: "需要预订航班和酒店两个订单。酒店要在#{@hotel_city}，入住日期是航班到达当天。"
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

    add_assertion "航班城市正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
      expect(@flight_booking.flight.departure_city).to eq(@departure_city),
        "出发城市错误。期望: #{@departure_city}, 实际: #{@flight_booking.flight.departure_city}"
      expect(@flight_booking.flight.destination_city).to eq(@arrival_city),
        "到达城市错误。期望: #{@arrival_city}, 实际: #{@flight_booking.flight.destination_city}"
    end

    add_assertion "航班日期正确（#{@flight_date}）", weight: 15 do
      expect(@flight_booking.flight.flight_date).to eq(@flight_date),
        "航班日期错误。期望: #{@flight_date}（后天）, 实际: #{@flight_booking.flight.flight_date}"
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

    add_assertion "酒店城市正确（#{@hotel_city}）", weight: 15 do
      expect(@hotel_booking.hotel.city).to eq(@hotel_city),
        "酒店城市错误。期望: #{@hotel_city}, 实际: #{@hotel_booking.hotel.city}"
    end

    add_assertion "酒店入住日期和时长正确", weight: 15 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（住1晚）, 实际: #{@hotel_booking.check_out_date}"
    end
  end

  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)

    flight = @available_flights.first
    Booking.create!(
      user: user,
      flight: flight,
      passenger_name: user.name,
      passenger_id_number: '110101199001011234',
      contact_phone: '13800138000',
      total_price: flight.price,
      accept_terms: true,
      status: 'paid',
      data_version: @data_version
    )

    hotel = @available_hotels.first
    room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
    HotelBooking.create!(
      user: user,
      hotel: hotel,
      hotel_room_id: room.id,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
      guest_name: user.name,
      guest_phone: '13800138000',
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
      check_out_date: @check_out_date.to_s
    }
  end

  def restore_from_state(data)
    @departure_city = data['departure_city']
    @arrival_city = data['arrival_city']
    @flight_date = Date.parse(data['flight_date'])
    @hotel_city = data['hotel_city']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])

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
