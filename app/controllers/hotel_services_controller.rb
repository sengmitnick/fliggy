class HotelServicesController < ApplicationController

  def index
    # Get city from params or default to '北京'
    @city = params[:city].presence || '北京'
    
    # Set default date params
    @check_in = params[:check_in] || Time.zone.today
    @check_out = params[:check_out] || (Time.zone.today + 1.day)
    
    # Load hotels with city and brand filter
    @hotels = Hotel.where.not(brand: [nil, '']).where(city: @city).order(display_order: :asc, created_at: :desc)
    @selected_brand = params[:brand]
    @hotels = @hotels.where(brand: @selected_brand) if @selected_brand.present?
    @brands = Hotel.where.not(brand: [nil, '']).where(city: @city).distinct.pluck(:brand).compact
  end

  def show
    @hotel = Hotel.find(params[:id])
    # Set default date params for hotel booking compatibility
    @check_in = params[:check_in] || Date.today.to_s
    @check_out = params[:check_out] || (Date.today + 1.day).to_s
    @rooms = params[:rooms] || 1
    @adults = params[:adults] || 2
    @children = params[:children] || 0
  end

  private
  # Write your private methods here
end
