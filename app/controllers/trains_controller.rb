class TrainsController < ApplicationController

  def index
    # City selector data
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
  end

  def show
    @train = Train.find(params[:id])
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
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
  end

  private
  # Write your private methods here
end
