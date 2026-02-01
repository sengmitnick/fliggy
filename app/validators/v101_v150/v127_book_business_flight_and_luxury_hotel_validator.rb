# frozen_string_literal: true

require_relative '../base_validator'

# V127: 预订商务舱航班+高档酒店（3晚）
module V101V150
  class V127BookBusinessFlightAndLuxuryHotelValidator < BaseValidator
  self.validator_id = 'v127_book_business_flight_and_luxury_hotel_validator'
  self.task_id = 'f8g9h0i1-2a3b-4c5d-6e7f-8a9b0c1d2e3f'
  self.title = '预订商务舱航班+高档酒店（3晚）'
  self.description = '预订3天后从北京到上海的商务舱航班，并预订上海市区高档酒店（4星级以上，当天入住3晚）'

  def prepare
    @departure_city = '北京'
    @arrival_city = '上海'
    @flight_date = Date.current + 3.days
    @seat_class = 'business'
    @hotel_city = '上海'
    @min_star_level = 4
    @check_in_date = @flight_date
    @check_out_date = @check_in_date + 3.days

    @available_flights = Flight.where(
      departure_city: @departure_city,
      destination_city: @arrival_city,
      flight_date: @flight_date,
      data_version: 0
    ).order(price: :asc)

    @available_hotels = Hotel.where(
      city: @hotel_city,
      data_version: 0
    ).where('star_level >= ?', @min_star_level).order(price: :asc)

    raise "未找到符合条件的航班" if @available_flights.empty?
    raise "未找到符合条件的酒店" if @available_hotels.empty?

    {
      task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}市区高档酒店（4星级以上），#{@check_in_date.strftime('%Y年%m月%d日')}入住，住3晚。",
      requirements: {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        hotel_city: @hotel_city,
        min_star_level: @min_star_level,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        nights: 3
      },
      hint: "预订航班，选择高档酒店（4星级或5星级），住3晚。"
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

    add_assertion "航班城市和日期正确", weight: 30 do
      expect(@flight_booking.flight.departure_city).to eq(@departure_city)
      expect(@flight_booking.flight.destination_city).to eq(@arrival_city)
      expect(@flight_booking.flight.flight_date).to eq(@flight_date)
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

    add_assertion "酒店是高档酒店（4星级以上）", weight: 15 do
      star_level = @hotel_booking.hotel.star_level
      expect(star_level).to be >= @min_star_level
    end

    add_assertion "酒店入住时间和时长正确", weight: 15 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（航班当天）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（住3晚）, 实际: #{@hotel_booking.check_out_date}"
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
    room = hotel.hotel_rooms.where(data_version: 0).order(price: :desc).first
    HotelBooking.create!(
      user: user,
      hotel: hotel,
      hotel_room_id: room.id,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
      guest_name: user.name,
      guest_phone: '13800138000',
      payment_method: '花呗',
      total_price: room.price * 3,
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
    ).order(price: :desc)
  end
  end
end
