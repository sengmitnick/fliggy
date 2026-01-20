class SpecialHotelsController < ApplicationController
  include CitySelectorDataConcern

  def index
    # Get city from params, default to 北京
    @city = params[:city] || '北京'
    
    # Start with city-specific featured hotels
    @hotels = Hotel.by_city(@city).where(is_featured: true)
    
    # Apply search query if provided
    if params[:query].present?
      query = params[:query].strip
      @hotels = @hotels.where('name LIKE ? OR brand LIKE ? OR address LIKE ?', 
                              "%#{query}%", "%#{query}%", "%#{query}%")
    end
    
    # Apply district/area filter
    if params[:district].present?
      @hotels = @hotels.where('address LIKE ?', "%#{params[:district]}%")
    end
    
    # Apply price range filter
    if params[:price_range].present?
      case params[:price_range]
      when '0-100'
        @hotels = @hotels.where('price < ?', 100)
      when '100-200'
        @hotels = @hotels.where('price >= ? AND price < ?', 100, 200)
      when '200-300'
        @hotels = @hotels.where('price >= ? AND price < ?', 200, 300)
      when '300+'
        @hotels = @hotels.where('price >= ?', 300)
      end
    end
    
    # Apply star rating filter
    if params[:stars].present?
      @hotels = @hotels.where(star_level: params[:stars].to_i)
    end
    
    # Apply sorting
    case params[:sort]
    when 'rating'
      @hotels = @hotels.order(rating: :desc, price: :asc)
    when 'distance'
      @hotels = @hotels.order(distance: :asc, price: :asc)
    else
      @hotels = @hotels.order(price: :asc)
    end
    
    # Limit results
    @hotels = @hotels.limit(20)
    
    # Extract districts from current city hotels for filter options
    @districts = extract_districts(@city)
    
    # If no hotels found for this city (and no search query), show all featured hotels
    @hotels = Hotel.where(is_featured: true).order(price: :asc).limit(20) if @hotels.empty? && params[:query].blank?
  end

  private
  
  # Extract unique districts/areas from hotel addresses in the current city
  def extract_districts(city)
    addresses = Hotel.by_city(city).where(is_featured: true).pluck(:address).compact
    
    districts = addresses.map do |address|
      # Extract district name (e.g., "南山区" from "南山区深圳湾")
      if address.match?(/(\w+区)/)
        address.match(/(\w+区)/)[1]
      elsif address.match?(/(\w+新区)/)
        address.match(/(\w+新区)/)[1]
      else
        # For addresses without district, try to extract first part
        address.split(/[路街道号]/).first
      end
    end.compact.uniq.sort
    
    districts
  end
  # Write your private methods here
end
