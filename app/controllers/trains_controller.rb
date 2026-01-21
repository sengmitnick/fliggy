class TrainsController < ApplicationController
  include CitySelectorDataConcern

  def index
    # NOTE: City selector data is loaded via CitySelectorDataConcern
    # Preload date prices for date picker modal (60 days from today)
    @departure_date_prices = preload_date_prices('北京', '杭州')
  end

  def show
    @train = Train.find(params[:id])
    # NOTE: City selector data is loaded via CitySelectorDataConcern
  end

  def search
    @departure_city = params[:departure_city] || "北京"
    @arrival_city = params[:arrival_city] || "杭州"
    @date = params[:date] ? Date.parse(params[:date]) : Time.zone.today
    @sort_by = params[:sort_by] || "departure_time" # departure_time, price, duration
    @only_high_speed = params[:only_high_speed] == "true"
    
    # Use model search method (no auto-generation)
    @trains = Train.search(
      @departure_city,
      @arrival_city,
      @date,
      only_high_speed: @only_high_speed,
      sort_by: @sort_by
    )
    
    # Preload date prices for date picker modal
    @departure_date_prices = preload_date_prices(@departure_city, @arrival_city)
  end

  private
  
  # Preload train prices for date picker (60 days from today)
  def preload_date_prices(departure_city, arrival_city)
    today = Date.today
    # Start from the 1st day of current month to match calendar display
    start_date = Date.new(today.year, today.month, 1)
    end_date = today + 60.days
    prices = {}
    
    # Calculate date range from start of month to end date
    days_range = (end_date - start_date).to_i
    
    # Generate trains for each date if they don't exist
    (0..days_range).each do |day_offset|
      date = start_date + day_offset.days
      
      # Check if trains exist for this date, if not, generate them
      existing_trains = Train.by_route(departure_city, arrival_city).by_date(date)
      if existing_trains.empty?
        Train.generate_for_route(departure_city, arrival_city, date)
      end
    end
    
    # Query all trains within the date range
    trains = Train.by_route(departure_city, arrival_city)
                  .where('DATE(departure_time) >= ? AND DATE(departure_time) <= ?', start_date, end_date)
                  .includes(:train_seats)
    
    # Group trains by date and find minimum price for each date
    trains.group_by { |t| t.departure_time.to_date }.each do |date, date_trains|
      # Get minimum price from train_seats (second_class price)
      min_price = date_trains.map do |train|
        train.train_seats.where(seat_type: 'second_class').minimum(:price) || train.price_second_class
      end.compact.min || 0
      
      prices[date] = min_price.to_i
    end
    
    prices
  end
end
