class HotelPackageOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @package_option = PackageOption.find(params[:package_option_id])
    @package = @package_option.hotel_package
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    
    # CRITICAL: Load existing pending order if it exists (for "back" button from order detail page)
    # This preserves dates, hotel, and other selections when user returns to edit
    existing_order = current_user.hotel_package_orders
                                  .where(status: 'pending')
                                  .where(package_option_id: params[:package_option_id])
                                  .order(created_at: :desc)
                                  .first
    
    # IMPORTANT: Always use a NEW record for the form to ensure POST method
    # We pre-fill the new record with data from existing order
    @order = HotelPackageOrder.new(quantity: 1)
    
    if existing_order
      # User is returning to edit existing order - pre-fill form with saved data
      @order.attributes = existing_order.attributes.except('id', 'created_at', 'updated_at', 'order_number')
      # Merge URL params with order data (URL params take precedence for explicit user changes)
      @order.quantity = params[:quantity].to_i if params[:quantity].present?
      @order.booking_type = params[:booking_type] if params[:booking_type].present?
    end
    
    # Get all package options for this package
    @all_package_options = @package.package_options.ordered.includes(:hotel_package)
    
    # Get available hotels grouped by city for booking modal
    @hotels_by_city = fetch_available_hotels_by_city(@package)
    
    # Get selected hotel: prioritize URL param, then order's saved hotel_id
    hotel_id = params[:hotel_id].presence || @order.hotel_id
    @selected_hotel = Hotel.find_by(id: hotel_id) if hotel_id.present?
  end

  def create
    # CRITICAL: Find existing pending order for this user and package_option
    # If user modifies dates and resubmits, we should update the existing order instead of creating duplicates
    existing_order = current_user.hotel_package_orders
                                  .where(status: 'pending')
                                  .where(package_option_id: params[:hotel_package_order][:package_option_id])
                                  .order(created_at: :desc)
                                  .first
    
    if existing_order
      # Update existing order with new data
      @order = existing_order
      @order.assign_attributes(order_params)
    else
      # Create new order
      @order = current_user.hotel_package_orders.build(order_params)
    end
    
    # CRITICAL: Set hotel_id from hidden_field_tag (not in order_params)
    # This preserves hotel selection when user returns to form
    @order.hotel_id = params[:hotel_id] if params[:hotel_id].present?
    
    @package_option = @order.package_option
    @package = @package_option.hotel_package
    
    # Calculate total price
    @order.total_price = @package_option.price * @order.quantity
    @order.hotel_package = @package
    @order.status = 'pending'  # Keep as pending, will be paid in show page
    
    # Set check-in and check-out dates if not provided
    if @order.check_in_date.blank?
      @order.check_in_date = Date.current + 5.days
      @order.check_out_date = @order.check_in_date + @package.night_count.days
    end
    
    if @order.save
      redirect_params = { id: @order.id }
      # CRITICAL: Only include dates in URL if user explicitly selected them (instant booking)
      # For stockup mode, don't pass dates so back button returns to original state
      if @order.booking_type == 'instant'
        redirect_params[:hotel_id] = params[:hotel_id] if params[:hotel_id].present?
        redirect_params[:check_in_date] = @order.check_in_date if @order.check_in_date.present?
        redirect_params[:check_out_date] = @order.check_out_date if @order.check_out_date.present?
      end
      redirect_to hotel_package_order_path(redirect_params)
    else
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      @all_package_options = @package.package_options.ordered.includes(:hotel_package)
      @hotels_by_city = fetch_available_hotels_by_city(@package)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = HotelPackageOrder.find(params[:id])
    @package = @order.hotel_package
    @package_option = @order.package_option
    @selected_hotel = Hotel.find_by(id: params[:hotel_id]) if params[:hotel_id].present?
  end

  def pay
    @order = HotelPackageOrder.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Just process the payment
    if @order.update(status: 'paid', purchased_at: Time.current)
      render json: { success: true }
    else
      render json: { success: false, message: '支付失败' }, status: :unprocessable_entity
    end
  end

  def success
    @order = HotelPackageOrder.find(params[:id])
    @package = @order.hotel_package
    @package_option = @order.package_option
  end

  private

  def order_params
    params.require(:hotel_package_order).permit(
      :package_option_id,
      :passenger_id,
      :quantity,
      :booking_type,
      :contact_name,
      :contact_phone,
      :check_in_date,
      :check_out_date,
      :room_count,
      :adult_count,
      :child_count
    )
  end
  
  def fetch_available_hotels_by_city(package)
    # Get hotels based on package location (city/region)
    hotels = Hotel.where(is_domestic: true)
    
    # Filter by city if specified
    if package.city.present?
      # Get hotels from the same city and nearby cities
      hotels = hotels.where(city: package.city)
    elsif package.region.present?
      # Get hotels from the same region
      hotels = hotels.where(region: package.region)
    end
    
    # Filter by brand if package has brand_name
    if package.brand_name.present?
      hotels = hotels.where("brand ILIKE ?", "%#{package.brand_name}%")
    end
    
    # Get featured hotels first, ordered by rating
    hotels = hotels.order(is_featured: :desc, rating: :desc, display_order: :asc)
                   .limit(20)
    
    # Group by city with count
    hotels_by_city = {}
    hotels.each do |hotel|
      city = hotel.city || '其他城市'
      hotels_by_city[city] ||= []
      hotels_by_city[city] << hotel
    end
    
    hotels_by_city
  end
end
