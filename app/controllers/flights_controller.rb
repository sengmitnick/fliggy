class FlightsController < ApplicationController

  def index
    # Flight search page with city selector
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
  end

  def search
    @departure_city = params[:departure_city] || '北京'
    @destination_city = params[:destination_city] || '杭州'
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @trip_type = params[:trip_type] || 'one_way'
    @return_date = params[:return_date].present? ? Date.parse(params[:return_date]) : nil

    # Get or generate flights for the outbound route and date
    @flights = Flight.search(@departure_city, @destination_city, @date)

    # Get prices for nearby dates (5 days)
    @date_prices = get_date_prices(@departure_city, @destination_city, @date)

    # For round trip, also get return flights
    if @trip_type == 'round_trip' && @return_date
      @return_flights = Flight.search(@destination_city, @departure_city, @return_date)
      @return_date_prices = get_date_prices(@destination_city, @departure_city, @return_date)
    end
  end

  def show
    @flight = Flight.includes(:flight_offers).find(params[:id])
    @offers = @flight.sorted_offers
  end

  private

  def get_date_prices(departure_city, destination_city, center_date)
    prices = []
    (-2..2).each do |offset|
      date = center_date + offset.days
      flights = Flight.search(departure_city, destination_city, date)
      min_price = flights.minimum(:price) || 0
      
      prices << {
        date: date,
        weekday: I18n.l(date, format: '%A'),
        day: date.day,
        price: min_price.to_i,
        is_today: date == center_date
      }
    end
    prices
  end
end
