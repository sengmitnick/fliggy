class DeepTravelBookingsController < ApplicationController
  before_action :authenticate_user!

  def new
    @full_render = true
    
    # Get parameters from URL
    @guide = DeepTravelGuide.includes(:deep_travel_products).find(params[:guide_id])
    @product = @guide.deep_travel_products.first
    @travel_date = params[:date]
    @adult_count = params[:adult_count].to_i
    @child_count = params[:child_count].to_i
    
    # Calculate pricing
    @adult_price = @product.price
    @child_price = (@product.price * 0.8).round
    @total_price = (@adult_count * @adult_price) + (@child_count * @child_price)
    @discount_amount = 0
    @final_price = @total_price
    
    # Get user's existing passengers
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    
    # Initialize booking object with booking_travelers
    @booking = DeepTravelBooking.new(
      user: current_user,
      deep_travel_guide: @guide,
      deep_travel_product: @product,
      travel_date: @travel_date,
      adult_count: @adult_count,
      child_count: @child_count,
      total_price: @final_price
    )
    
    # Build booking_travelers based on adult and child count
    @adult_count.times { @booking.booking_travelers.build(traveler_type: 'adult') }
    @child_count.times { @booking.booking_travelers.build(traveler_type: 'child') }
  end

  def create
    @booking = DeepTravelBooking.new(booking_params)
    @booking.user = current_user
    
    if @booking.save
      redirect_to deep_travel_booking_path(@booking), notice: '预订成功,请完成支付'
    else
      # Set up instance variables needed by the new template
      @guide = @booking.deep_travel_guide
      @product = @booking.deep_travel_product
      @travel_date = @booking.travel_date
      @adult_count = @booking.adult_count
      @child_count = @booking.child_count
      
      # Calculate pricing
      @adult_price = @product.price
      @child_price = (@product.price * 0.8).round
      @total_price = (@adult_count * @adult_price) + (@child_count * @child_price)
      @discount_amount = 0
      @final_price = @total_price
      
      # Get user's existing passengers
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.deep_travel_bookings.find(params[:id])
    @guide = @booking.deep_travel_guide
    @product = @booking.deep_travel_product
  end

  def pay
    @booking = current_user.deep_travel_bookings.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    @booking.update!(status: :paid)
    
    render json: { success: true }
  end

  def success
    @booking = current_user.deep_travel_bookings.find(params[:id])
    @guide = @booking.deep_travel_guide
    @product = @booking.deep_travel_product
  end

  def destroy
    # Cancel booking logic
    @booking = current_user.deep_travel_bookings.find(params[:id])
    
    if @booking.status_pending?
      @booking.update(status: :cancelled)
      redirect_to deep_travels_path, notice: '预订已取消'
    else
      redirect_to deep_travels_path, alert: '无法取消此预订'
    end
  end

  private
  
  def booking_params
    params.require(:deep_travel_booking).permit(
      :deep_travel_guide_id,
      :deep_travel_product_id,
      :travel_date,
      :adult_count,
      :child_count,
      :contact_name,
      :contact_phone,
      :total_price,
      :insurance_price,
      :notes,
      :fill_travelers_later,
      :terms_agreed,
      booking_travelers_attributes: [:id, :traveler_name, :id_number, :traveler_type, :_destroy]
    )
  end
end
