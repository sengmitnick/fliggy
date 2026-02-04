class TrainsController < ApplicationController
  include CitySelectorDataConcern

  # City to stations mapping
  CITY_STATIONS = {
    "北京" => ["北京站", "北京西站", "北京南站", "北京北站"],
    "上海" => ["上海站", "上海虹桥站", "上海南站"],
    "杭州" => ["杭州站", "杭州东站", "杭州南站"],
    "天津" => ["天津站", "天津西站", "天津南站"],
    "广州" => ["广州站", "广州东站", "广州南站", "广州北站"],
    "深圳" => ["深圳站", "深圳北站", "深圳东站"],
    "南京" => ["南京站", "南京南站"],
    "苏州" => ["苏州站", "苏州北站"],
    "武汉" => ["武汉站", "武昌站", "汉口站"],
    "成都" => ["成都站", "成都东站", "成都南站"],
    "重庆" => ["重庆站", "重庆北站", "重庆西站"],
    "西安" => ["西安站", "西安北站", "西安南站"],
    "郑州" => ["郑州站", "郑州东站"],
    "长沙" => ["长沙站", "长沙南站"],
    "济南" => ["济南站", "济南西站"],
    "青岛" => ["青岛站", "青岛北站"],
    "沈阳" => ["沈阳站", "沈阳北站", "沈阳南站"],
    "大连" => ["大连站", "大连北站"],
    "哈尔滨" => ["哈尔滨站", "哈尔滨西站", "哈尔滨东站"],
    "福州" => ["福州站", "福州南站"],
    "厦门" => ["厦门站", "厦门北站"],
    "昆明" => ["昆明站", "昆明南站"],
    "贵阳" => ["贵阳站", "贵阳北站", "贵阳东站"],
    "南昌" => ["南昌站", "南昌西站"],
    "合肥" => ["合肥站", "合肥南站"]
  }.freeze

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
    
    # Get station lists for current cities
    @departure_stations = CITY_STATIONS[@departure_city] || [@departure_city]
    @arrival_stations = CITY_STATIONS[@arrival_city] || [@arrival_city]
    
    # Preload date prices for date picker modal (only query existing data)
    @departure_date_prices = preload_date_prices(@departure_city, @arrival_city)
    
    # Use model search method (no auto-generation)
    @trains = Train.search(
      @departure_city,
      @arrival_city,
      @date,
      only_high_speed: @only_high_speed,
      sort_by: @sort_by,
      sort_order: @sort_order
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
