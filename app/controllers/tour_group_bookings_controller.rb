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
    (@adult_count + @child_count).times do
      @booking.booking_travelers.build(traveler_type: 'adult')
    end
    
    # 预填联系人信息（使用当前用户信息）
    @booking.contact_name = current_user.email.split('@').first if current_user.email.present?
    @booking.contact_phone = current_user.phone if current_user.respond_to?(:phone)
  end

  def create
    @product = TourGroupProduct.includes(:tour_packages, :tour_itinerary_days).find(params[:tour_group_booking][:tour_group_product_id])
    @package = TourPackage.find(params[:tour_group_booking][:tour_package_id])
    
    @booking = TourGroupBooking.new(booking_params)
    @booking.user = current_user
    @booking.tour_group_product = @product
    @booking.tour_package = @package
    
    # 计算总价
    @booking.total_price = @booking.calculate_total_price
    
    if @booking.save
      redirect_to tour_group_path(@product), notice: '订单创建成功！'
    else
      # 设置视图需要的实例变量（用于重新渲染表单）
      @travel_date = @booking.travel_date || Date.today
      @adult_count = @booking.adult_count || 1
      @child_count = @booking.child_count || 0
      render :new
    end
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
