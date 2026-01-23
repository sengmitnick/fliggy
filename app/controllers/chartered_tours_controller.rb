class CharteredToursController < ApplicationController
  before_action :authenticate_user!

  def index
    # 获取当前选中的城市（默认武汉）
    @selected_city = City.find_by(name: params[:city] || '武汉')
    
    # 获取热门城市
    @hot_cities = City.where(name: ['东京', '大阪', '京都', '冲绳', '北海道', '清迈', '普吉岛', '曼谷'])
    
    # 获取武汉的精选路线（首页展示3个）
    @featured_routes = CharterRoute.includes(:city, :attractions)
                                   .where(city: @selected_city, category: 'featured')
                                   .order(created_at: :desc)
                                   .limit(3)
    
    # 获取热门景点（首页展示3个）
    @popular_attractions = Attraction.where(city: @selected_city)
                                     .order(created_at: :desc)
                                     .limit(3)
    
    # 设置默认出发日期为明天
    @default_departure_date = (Date.today + 1.day).strftime('%m月%d日')
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
