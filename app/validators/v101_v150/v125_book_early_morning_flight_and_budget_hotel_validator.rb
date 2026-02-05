# frozen_string_literal: true

require_relative '../base_validator'

# V125: 预订明天早班航班+经济型酒店（提前一晚入住）
module V101V150
  class V125BookEarlyMorningFlightAndBudgetHotelValidator < BaseValidator
  self.validator_id = 'v125_book_early_morning_flight_and_budget_hotel_validator'
  self.task_id = '661e90ec-e0f0-4519-a868-44e3d3e327c9'
  self.title = '预订明天早班航班+经济型酒店（提前一晚入住）'
  self.description = '预订明天早上8点前从北京到上海的航班，并预订北京首都机场附近的经济型酒店（今晚入住1晚）'
  self.timeout_seconds = 300

  def prepare
    @departure_city = '北京'
    @arrival_city = '上海'
    @flight_date = Date.current + 1.day
    @hotel_city = '北京'
    @check_in_date = Date.current
    @check_out_date = @flight_date

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
    ).where('price < ?', 300).order(price: :asc)

    raise "未找到符合条件的航班" if @available_flights.empty?
    raise "未找到符合条件的酒店" if @available_hotels.empty?

    {
      task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（明天）早上8点前从#{@departure_city}到#{@arrival_city}的航班，并预订#{@hotel_city}首都机场附近的经济型酒店（300元以下），#{@check_in_date.strftime('%Y年%m月%d日')}（今晚）入住，住1晚。",
      requirements: {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date,
        departure_time_before: '08:00',
        hotel_city: @hotel_city,
        hotel_max_price: 300,
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

    add_assertion "航班城市和日期正确", weight: 15 do
      expect(@flight_booking.flight.departure_city).to eq(@departure_city)
      expect(@flight_booking.flight.destination_city).to eq(@arrival_city)
      expect(@flight_booking.flight.flight_date).to eq(@flight_date)
    end

    add_assertion "航班是早班（8点前起飞）", weight: 15 do
      hour = @flight_booking.flight.departure_time.hour
      expect(hour).to be < 8
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

    add_assertion "酒店是经济型（300元以下）", weight: 15 do
      hotel_price = @hotel_booking.hotel.price
      expect(hotel_price).to be < 300
    end

    add_assertion "酒店入住时间正确（提前一晚）", weight: 15 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}（今晚，航班前一晚）, 实际: #{@hotel_booking.check_in_date}"
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "退房日期错误。期望: #{@check_out_date}（明天，航班当天）, 实际: #{@hotel_booking.check_out_date}"
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
    ).order(price: :asc)
  end
  end
end
