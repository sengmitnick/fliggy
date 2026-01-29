class HotelPackageOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @package_option = PackageOption.find(params[:package_option_id])
    @package = @package_option.hotel_package
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    @order = HotelPackageOrder.new(quantity: 1)
    
    # Get all package options for this package
    @all_package_options = @package.package_options.ordered.includes(:hotel_package)
    
    # Get available hotels grouped by city for booking modal
    @hotels_by_city = fetch_available_hotels_by_city(@package)
    
    # Get selected hotel if hotel_id is provided (for instant booking)
    @selected_hotel = Hotel.find_by(id: params[:hotel_id]) if params[:hotel_id].present?
  end

  def create
    @order = current_user.hotel_package_orders.build(order_params)
    @package_option = @order.package_option
    @package = @package_option.hotel_package
    
    # Calculate total price
    @order.total_price = @package_option.price * @order.quantity
    @order.hotel_package = @package
    @order.status = 'pending'  # Create as pending, will be paid in show page
    
    # Set check-in and check-out dates if not provided
    if @order.check_in_date.blank?
      @order.check_in_date = Date.current + 5.days
      @order.check_out_date = @order.check_in_date + @package.night_count.days
    end
    
    if @order.save
      redirect_to hotel_package_order_path(@order)
    else
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = HotelPackageOrder.find(params[:id])
    @package = @order.hotel_package
    @package_option = @order.package_option
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
      :contact_phone
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
