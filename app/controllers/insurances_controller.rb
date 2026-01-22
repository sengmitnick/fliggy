class InsurancesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Homepage: featured and official select products
    @featured_products = InsuranceProduct.active.featured.sorted.limit(6)
    @official_products = InsuranceProduct.active.official_select.sorted.limit(4)
    
    # Group by product_type for tabs
    @domestic_count = InsuranceProduct.active.domestic.count
    @international_count = InsuranceProduct.active.international.count
    @transport_count = InsuranceProduct.active.transport.count
  end

  def search
    @products = InsuranceProduct.active

    # Filter by city (if provided)
    if params[:city_id].present?
      @city = City.find_by(id: params[:city_id])
      if @city
        @products = @products.available_in_city(@city.id)
      end
    elsif params[:destination].present?
      # Try to find city by name
      @city = City.find_by(name: params[:destination])
      if @city
        @products = @products.available_in_city(@city.id)
      end
    end

    # Filter by product_type (destination_type from params)
    if params[:destination_type].present?
      case params[:destination_type]
      when 'domestic'
        @products = @products.domestic
      when 'international'
        @products = @products.international
      when 'transport'
        @products = @products.transport
      end
    end

    # Filter by company
    if params[:company].present?
      @products = @products.by_company(params[:company])
    end

    # Filter by scenes (activities)
    if params[:scenes].present?
      @products = @products.with_scenes(params[:scenes])
    end

    # Filter by date range (calculate days)
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]) rescue nil
      end_date = Date.parse(params[:end_date]) rescue nil
      
      if start_date && end_date
        days = (end_date - start_date).to_i + 1
        @products = @products.where('min_days <= ? AND max_days >= ?', days, days)
        @days = days
      end
    end

    # Filter by destination
    @destination = params[:destination]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @city_id = @city&.id

    # Sort
    @products = @products.sorted

    # Available filter options
    @available_companies = InsuranceProduct.active.distinct.pluck(:company).compact
    @available_scenes = InsuranceProduct.active.pluck(:scenes).flatten.uniq.compact
  end

  def show
    @product = InsuranceProduct.find(params[:id])
    
    # Extract dates and city from params for price calculation
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @destination = params[:destination]
    @city_id = params[:city_id]
    
    # Find city if provided
    if @city_id.present?
      @city = City.find_by(id: @city_id)
    elsif @destination.present?
      @city = City.find_by(name: @destination)
      @city_id = @city&.id
    end
    
    if @start_date.present? && @end_date.present?
      start_date = Date.parse(@start_date) rescue nil
      end_date = Date.parse(@end_date) rescue nil
      
      if start_date && end_date
        @days = (end_date - start_date).to_i + 1
        @calculated_price = @product.calculate_price(@days, city_id: @city_id)
      end
    end

    # Related products from same company
    @related_products = InsuranceProduct.active
      .where(company: @product.company)
      .where.not(id: @product.id)
      .sorted
      .limit(4)
  end

  private
  # Write your private methods here
end
