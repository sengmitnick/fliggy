class CharteredToursController < ApplicationController
  before_action :authenticate_user!

  def index
    # 定制旅游首页 - 展示个人定制和公司团建两个tab
    # 目前默认显示个人定制tab
    @active_tab = params[:tab] || 'personal'
  end

  def search
    # 包车游城市搜索页面 - 展示城市选择、日期选择、精挑路线
    @selected_city = params[:city].present? ? City.find_by(name: params[:city]) : City.find_by(name: '武汉')
    @departure_date = params[:date].present? ? Date.parse(params[:date]) : (Date.current + 1.day)
    @active_tab = params[:tab] || 'recommend' # recommend, classic, hot
    
    # 获取该城市的包车路线
    if @selected_city
      @routes = CharterRoute.where(city: @selected_city)
      @routes = case @active_tab
                when 'classic'
                  @routes.classic
                when 'hot'
                  @routes.hot
                else
                  @routes.featured
                end
      @routes = @routes.includes(:city, :attractions).order(:name)
    else
      @routes = CharterRoute.none
    end
    
    # 获取热门城市列表（用于城市选择器）
    @hot_cities = City.where(name: ['武汉', '上海', '北京', '广州', '深圳', '杭州', '成都', '西安'])
  end

  def vehicles
    # 车型选择页面 - 显示不同时长和车型的价格
    @route = CharterRoute.friendly.find(params[:route_id])
    @departure_date = params[:departure_date].present? ? Date.parse(params[:departure_date]) : Date.tomorrow
    @duration_hours = params[:duration_hours]&.to_i || 6
    @passenger_count = params[:passenger_count]&.to_i || 1
    
    # 获取所有车型
    @vehicle_types = VehicleType.order(:category, :level)
    
    # 为每个车型计算价格（使用CharterPriceCalculatorService）
    @vehicle_prices = @vehicle_types.each_with_object({}) do |vehicle, hash|
      price = CharterPriceCalculatorService.call(
        route: @route,
        vehicle_type: vehicle,
        duration_hours: @duration_hours,
        departure_date: @departure_date
      )
      hash[vehicle.id] = price
    end
  end

  private
  # Write your private methods here
end
