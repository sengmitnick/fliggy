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
    @order.status = 'paid'  # Mark as paid after payment confirmation
    
    if @order.save
      redirect_to success_hotel_package_order_path(@order)
    else
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = HotelPackageOrder.find(params[:id])
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
