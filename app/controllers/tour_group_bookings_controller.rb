class TourGroupBookingsController < ApplicationController
  before_action :authenticate_user!

  def new
    @product = TourGroupProduct.includes(:tour_packages, :tour_itinerary_days).find(params[:product_id])
    @package = @product.tour_packages.find(params[:package_id])
    
    # 从参数中获取选择的信息
    @travel_date = params[:travel_date].present? ? Date.parse(params[:travel_date]) : Date.today
    @adult_count = (params[:adult_count] || 1).to_i
    @child_count = (params[:child_count] || 0).to_i
    
    # 构建订单对象
    @booking = TourGroupBooking.new(
      tour_group_product: @product,
      tour_package: @package,
      user: current_user,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: @child_count,
      insurance_type: 'none'
    )
    
    # 预填出行人（从当前用户的乘客信息中获取）
    # 先添加成人
    @adult_count.times do
      @booking.booking_travelers.build(traveler_type: 'adult')
    end
    # 再添加儿童
    @child_count.times do
      @booking.booking_travelers.build(traveler_type: 'child')
    end
  end

  def create
    @product = TourGroupProduct.includes(:tour_packages, :tour_itinerary_days).find(params[:tour_group_booking][:tour_group_product_id])
    @package = TourPackage.find(params[:tour_group_booking][:tour_package_id])
    
    @booking = TourGroupBooking.new(booking_params)
    @booking.user = current_user
    @booking.tour_group_product = @product
    @booking.tour_package = @package
    @booking.status = 'pending'
    
    # 计算总价
    @booking.total_price = @booking.calculate_total_price
    
    if @booking.save
      redirect_to tour_group_booking_path(@booking), notice: '订单创建成功，请确认并支付'
    else
      # 设置视图需要的实例变量（用于重新渲染表单）
      @travel_date = @booking.travel_date || Date.today
      @adult_count = @booking.adult_count || 1
      @child_count = @booking.child_count || 0
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.tour_group_bookings.includes(:tour_group_product, :tour_package).find(params[:id])
    @product = @booking.tour_group_product
    @package = @booking.tour_package
  end

  def pay
    @booking = current_user.tour_group_bookings.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Just process the payment
    @booking.update!(status: 'confirmed')
    
    render json: { success: true }
  end

  def success
    @booking = current_user.tour_group_bookings.includes(:tour_group_product, :tour_package, :booking_travelers).find(params[:id])
    @product = @booking.tour_group_product
    @package = @booking.tour_package
  end

  def destroy
    # Write your real logic here
  end

  private
  
  def booking_params
    params.require(:tour_group_booking).permit(
      :travel_date,
      :adult_count,
      :child_count,
      :contact_name,
      :contact_phone,
      :insurance_type,
      booking_travelers_attributes: [:id, :traveler_name, :id_number, :traveler_type, :_destroy]
    )
  end
end
