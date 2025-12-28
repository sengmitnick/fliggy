class TrainsController < ApplicationController

  def index
    # Write your real logic here
  end


  def search
    @departure_city = params[:departure_city] || "北京"
    @arrival_city = params[:arrival_city] || "杭州"
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @sort_by = params[:sort_by] || "departure_time" # departure_time, price, duration
    @only_high_speed = params[:only_high_speed] == "true"
    
    # Use model search method with automatic generation
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
