class HotelPackagesController < ApplicationController

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
    @city = params[:city]
    @sort_by = params[:sort_by] # sales, distance, star, brand
    @filter_tags = params[:tags] || [] # refundable, luxury, instant_booking
    
    @packages = HotelPackage.all
    
    # City filter
    @packages = @packages.by_city(@city) if @city.present?
    
    # Search query
    if @query.present?
      @packages = @packages.where('brand_name LIKE ? OR title LIKE ? OR description LIKE ? OR region LIKE ?', 
                                   "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%")
    end
    
    # Tag filters
    @packages = @packages.refundable if @filter_tags.include?('refundable')
    @packages = @packages.luxury if @filter_tags.include?('luxury')
    @packages = @packages.instant_booking if @filter_tags.include?('instant_booking')
    
    # Sorting
    case @sort_by
    when 'sales'
      @packages = @packages.ordered_by_sales
    else
      @packages = @packages.ordered
    end
    
    @packages = @packages.page(params[:page]).per(10)
  end

  def show
    @package = HotelPackage.friendly.find(params[:id])
  end

  private
  # Write your private methods here
end
