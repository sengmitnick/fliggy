class SpecialFlightsController < ApplicationController

  def index
    # Special price flights search page with multi-city selector and fuzzy date picker
    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
    
    # Initialize with default cities (can be multiple for destination)
    @departure_city = params[:departure_city] || '深圳'
    @destination_cities = params[:destination_cities]&.split(',') || ['杭州', '武汉']
  end


end
