class CharterRoutesController < ApplicationController
  before_action :authenticate_user!

  def show
    # 路线详情页 - 展示路线详情、静态地图、景点列表
    @route = CharterRoute.friendly.find(params[:id])
    @city = @route.city
    @attractions = @route.attractions.order('route_attractions.position')
    
    # 获取出发日期（默认明天）
    @departure_date = params[:departure_date].present? ? Date.parse(params[:departure_date]) : Date.tomorrow
    
    # 静态地图图片（使用Unsplash占位图）
    @map_image_url = "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=400&fit=crop"
  end

  def search
    # 路线搜索页面 - 按城市、类别筛选路线
    @city = params[:city].present? ? City.find_by(name: params[:city]) : City.find_by(name: '武汉')
    @category = params[:category] || 'all'
    
    # 获取路线列表
    @routes = CharterRoute.includes(:city, :attractions)
                          .where(city: @city)
    
    # 按类别筛选
    @routes = @routes.where(category: @category) unless @category == 'all'
    
    @routes = @routes.order(created_at: :desc)
    
    # 静态地图图片（显示所有路线的起点）
    @map_image_url = "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=400&fit=crop"
  end

  private
  # Write your private methods here
end
