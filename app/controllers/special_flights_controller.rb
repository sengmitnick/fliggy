class SpecialFlightsController < ApplicationController

  def index
    # Special price flights search page with multi-city selector and fuzzy date picker
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
    
    # Initialize with default cities (can be multiple for destination)
    @departure_city = params[:departure_city] || '深圳'
    @destination_cities = params[:destination_cities]&.split(',') || ['杭州', '武汉']
  end

  def search
    @departure_city = params[:departure_city] || '深圳'
    destination_cities_param = params[:destination_cities]
    
    # Validate destination cities
    if destination_cities_param.blank?
      redirect_to special_flights_path, alert: '请至少选择一个目的地城市'
      return
    end
    
    @destination_cities = destination_cities_param.split(',')
    
    # Validate date
    if params[:date].blank?
      redirect_to special_flights_path, alert: '请选择出发日期'
      return
    end
    
    # Handle fuzzy date format for special flights
    if params[:date].present? && params[:date].start_with?('fuzzy:')
      # Extract months from fuzzy date format: fuzzy:2026-01,2026-02
      months_string = params[:date].sub('fuzzy:', '')
      @selected_months = months_string.split(',')
      @is_fuzzy_date = true
    else
      @date = params[:date].present? ? Date.parse(params[:date]) : nil
      @is_fuzzy_date = false
    end
    
    # Search for special price flights across all destination cities
    @special_offers = []
    
    @destination_cities.each do |dest_city|
      if @is_fuzzy_date
        # Find cheapest flights in selected months
        @selected_months.each do |month_str|
          year, month = month_str.split('-').map(&:to_i)
          start_date = Date.new(year, month, 1)
          end_date = start_date.end_of_month
          
          # Search flights in this month
          (start_date..end_date).each do |date|
            flights = Flight.search(@departure_city, dest_city, date)
            flights.each do |flight|
              # Only include flights with significant discount (< 300 yuan or discount > 20%)
              if flight.price < 300 || (flight.discount_price > 0 && flight.discount_percent > 20)
                @special_offers << {
                  flight: flight,
                  destination: dest_city,
                  date: date,
                  discount_label: "超低#{flight.discount_percent.to_i}折"
                }
              end
            end
          end
        end
      elsif @date
        # Search for specific date
        flights = Flight.search(@departure_city, dest_city, @date)
        flights.each do |flight|
          if flight.price < 300 || (flight.discount_price > 0 && flight.discount_percent > 20)
            @special_offers << {
              flight: flight,
              destination: dest_city,
              date: @date,
              discount_label: "超低#{flight.discount_percent.to_i}折"
            }
          end
        end
      end
    end
    
    # Sort by price (cheapest first)
    @special_offers.sort_by! { |offer| offer[:flight].price }
  end
end
