class DestinationsController < ApplicationController

  def index
    # 如果用户之前选择过城市，跳转到该城市详情页
    if session[:last_destination_slug].present?
      redirect_to destination_path(session[:last_destination_slug]) and return
    end
    
    # 首次访问，跳转到默认城市（深圳）
    default_destination = Destination.friendly.find('shen-zhen')
    session[:last_destination_slug] = default_destination.slug
    redirect_to destination_path(default_destination.slug)
  end
  
  def select
    # 显示城市选择modal页面
    @destinations = Destination.hot_destinations.order(name: :asc)
    @current_location = session[:last_destination_slug] ? Destination.friendly.find(session[:last_destination_slug]).name : "深圳"
    
    # 获取所有城市
    @all_cities = City.all.order(:pinyin)
    
    # 按省份分组
    @cities_by_region = @all_cities.group_by(&:region)
    
    # 按主题分组
    @hot_cities = City.hot_cities.order(:pinyin)
    @beach_cities = City.by_theme("海边度假").order(:pinyin)
    @family_cities = City.by_theme("亲子必去").order(:pinyin)
    
    # 获取所有省份（排序）
    @regions = @cities_by_region.keys.sort
  end

  def show
    @destination = Destination.friendly.find(params[:id])
    
    # 记录用户选择的城市
    session[:last_destination_slug] = @destination.slug
    
    # 获取不同分类的产品
    @local_attractions = @destination.tour_products.by_category('local').by_type('attraction').by_rank.limit(3)
    @local_hotels = @destination.tour_products.by_category('local').by_type('hotel').by_rank.limit(3)
    @local_tours = @destination.tour_products.by_category('local').by_type('tour').by_rank.limit(10)
    
    @nearby_tours = @destination.tour_products.by_category('nearby').by_rank.limit(10)
    @seasonal_products = @destination.tour_products.by_category('seasonal').by_rank.limit(10)
    @experiences = @destination.tour_products.by_category('experience').by_rank.limit(10)
  end

  private
  # Write your private methods here
end
