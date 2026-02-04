class TrainsController < ApplicationController
  include CitySelectorDataConcern

  def index
    # NOTE: City selector data is loaded via CitySelectorDataConcern
    # Preload date prices for date picker modal (only query existing data)
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
    @sort_order = params[:sort_order] || "asc" # asc, desc
    @only_high_speed = params[:only_high_speed] == "true"
    
    # Advanced filter params
    @train_types = params[:train_types]&.split(',') || []
    @departure_time_start = params[:departure_time_start]&.to_i || 0
    @departure_time_end = params[:departure_time_end]&.to_i || 1440
    @arrival_time_start = params[:arrival_time_start]&.to_i || 0
    @arrival_time_end = params[:arrival_time_end]&.to_i || 1440
    
    # Preload date prices for date picker modal (only query existing data)
    @departure_date_prices = preload_date_prices(@departure_city, @arrival_city)
    
    # Use model search method with advanced filters
    @trains = Train.search(
      @departure_city,
      @arrival_city,
      @date,
      only_high_speed: @only_high_speed,
      sort_by: @sort_by,
      sort_order: @sort_order,
      train_types: @train_types,
      departure_time_start: @departure_time_start,
      departure_time_end: @departure_time_end,
      arrival_time_start: @arrival_time_start,
      arrival_time_end: @arrival_time_end
    )
  end

  private
  
  # Query existing train prices for date picker (NO auto-generation)
  def preload_date_prices(departure_city, arrival_city)
    today = Time.zone.today
    start_date = Date.new(today.year, today.month, 1)
    end_date = today + 60.days
    prices = {}
    
    # Only query existing trains, never generate new data
    trains = Train.by_route(departure_city, arrival_city)
                  .where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') >= ? AND DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') <= ?", start_date, end_date)
                  .includes(:train_seats)
    
    trains.group_by { |t| t.departure_time.to_date }.each do |date, date_trains|
      min_price = date_trains.map do |train|
        train.train_seats.where(seat_type: 'second_class').minimum(:price) || train.price_second_class
      end.compact.min || 0
      
      prices[date] = min_price.to_i
    end
    
    prices
  end
end
