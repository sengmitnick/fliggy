class CarsController < ApplicationController

  def index
    # 获取用户当前选择的城市（从session中读取目的地信息）
    @current_city = if session[:last_destination_slug].present?
      destination = Destination.friendly.find(session[:last_destination_slug])
      destination.name
    else
      '深圳' # 默认深圳
    end
    
    @cars = Car.where(is_available: true).order(:sales_rank)
    
    # 按分类统计
    @categories = Car.where(is_available: true).group(:category).count
    
    # 如果有分类筛选
    if params[:category].present?
      @cars = @cars.where(category: params[:category])
    end
    
    # 如果有排序
    if params[:sort] == 'price_asc'
      @cars = @cars.order(:price_per_day)
    elsif params[:sort] == 'price_desc'
      @cars = @cars.order(price_per_day: :desc)
    end
  end
  
  def search
    # 基础查询
    @cars = Car.where(is_available: true)
    
    # 根据城市筛选
    if params[:city].present?
      @cars = @cars.where(location: params[:city])
    end
    
    # 根据取车地点筛选
    if params[:pickup_location].present?
      @cars = @cars.where(pickup_location: params[:pickup_location])
    end
    
    # 按分类统计（基于筛选后的结果）
    @categories = @cars.group(:category).count
    
    # 如果有分类筛选
    if params[:category].present?
      @cars = @cars.where(category: params[:category])
    end
    
    # 如果有排序
    if params[:sort] == 'price_asc'
      @cars = @cars.order(:price_per_day)
    elsif params[:sort] == 'price_desc'
      @cars = @cars.order(price_per_day: :desc)
    else
      # 默认按销量排序
      @cars = @cars.order(:sales_rank)
    end
    
    # 存储搜索条件用于显示
    @search_params = {
      city: params[:city],
      pickup_location: params[:pickup_location],
      return_location: params[:return_location],
      pickup_date: params[:pickup_date],
      return_date: params[:return_date]
    }
  end
  
  # API endpoint to get locations by city
  def locations
    city = params[:city]
    if city.blank?
      render json: { error: 'City parameter is required' }, status: :bad_request
      return
    end

    # Get all unique pickup locations for the city
    pickup_locations = Car.where(location: city)
                          .where.not(pickup_location: nil)
                          .distinct
                          .pluck(:pickup_location)

    # Categorize locations
    airports = pickup_locations.select { |loc| loc.include?('机场') }
    train_stations = pickup_locations.select { |loc| loc.include?('站') && !loc.include?('机场') }
    others = pickup_locations - airports - train_stations

    render json: {
      city: city,
      locations: {
        airports: airports,
        train_stations: train_stations,
        others: others
      }
    }
  end
  
  def show
    @car = Car.find(params[:id])
    
    # 保存搜索参数用于传递到订单页面
    @search_params = {
      city: params[:city],
      pickup_location: params[:pickup_location],
      return_location: params[:return_location],
      pickup_date: params[:pickup_date],
      return_date: params[:return_date]
    }
  end

  private
  # Write your private methods here
end
