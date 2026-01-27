class HotelPackageOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @package_option = PackageOption.find(params[:package_option_id])
    @package = @package_option.hotel_package
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    @order = HotelPackageOrder.new(quantity: 1)
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
end
