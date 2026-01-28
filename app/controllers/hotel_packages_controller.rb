class HotelPackagesController < ApplicationController
  include CitySelectorDataConcern

  def index
    @hot_cities = City.where(is_hot: true).limit(4)
    @packages = HotelPackage.ordered
    
    # Filter by brand
    @packages = @packages.by_brand(params[:brand]) if params[:brand].present?
    
    # Filter by region
    @packages = @packages.by_region(params[:region]) if params[:region].present?
    
    @packages = @packages.page(params[:page]).per(10)
  end


  def search
    @query = params[:q]
    @city = params[:city] || '武汉'
    @sort_by = params[:sort_by] # '', 'sales', 'price_asc', 'price_desc'
    @filter_tags = params[:tags] || [] # refundable, luxury, instant_booking
    
    @packages = HotelPackage.all
    
    # City filter
    @packages = @packages.by_city(@city) if @city.present?
    
    # Search query
    if @query.present?
      @packages = @packages.where('brand_name LIKE ? OR title LIKE ? OR description LIKE ? OR region LIKE ?', 
                                   "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%")
    end
    
    # District filter (商圈筛选)
    if params[:district].present?
      @packages = @packages.where('region LIKE ?', "%#{params[:district]}%")
    end
    
    # Star level filter (星级筛选 - 基于hotel_packages表的star_level字段)
    if params[:star_level].present?
      @packages = @packages.where(star_level: params[:star_level])
    end
    
    # Brand filter (品牌筛选)
    if params[:brand].present?
      @packages = @packages.where('brand_name LIKE ? OR brand LIKE ?', "%#{params[:brand]}%", "%#{params[:brand]}%")
    end
    
    # Tag filters
    @packages = @packages.refundable if @filter_tags.include?('refundable')
    @packages = @packages.luxury if @filter_tags.include?('luxury')
    @packages = @packages.instant_booking if @filter_tags.include?('instant_booking')
    
    # Sorting
    case @sort_by
    when 'sales'
      @packages = @packages.ordered_by_sales
    when 'price_asc'
      @packages = @packages.order(price: :asc)
    when 'price_desc'
      @packages = @packages.order(price: :desc)
    else
      @packages = @packages.ordered
    end
    
    # 获取筛选选项数据
    @districts = HotelPackage.by_city(@city).distinct.pluck(:region).compact.reject(&:blank?).sort
    @brands = HotelPackage.by_city(@city).distinct.pluck(:brand_name).compact.reject(&:blank?).sort
    
    @packages = @packages.page(params[:page]).per(10)
  end

  def show
    @package = HotelPackage.friendly.find(params[:id])
  end

  private
  # Write your private methods here
end
