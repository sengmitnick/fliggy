class HotelServicesController < ApplicationController

  def index
    # Load hotels with brand filter
    @hotels = Hotel.where.not(brand: [nil, '']).order(display_order: :asc, created_at: :desc)
    @selected_brand = params[:brand]
    @hotels = @hotels.where(brand: @selected_brand) if @selected_brand.present?
    @brands = Hotel.where.not(brand: [nil, '']).distinct.pluck(:brand).compact
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
