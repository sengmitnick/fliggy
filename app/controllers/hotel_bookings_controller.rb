class HotelBookingsController < ApplicationController

  def new
    @hotel = Hotel.find(params[:hotel_id])
    @hotel_room = @hotel.hotel_rooms.find(params[:room_id])
    
    @booking = HotelBooking.new(
      hotel: @hotel,
      hotel_room: @hotel_room,
      check_in_date: params[:check_in] || Time.zone.today,
      check_out_date: params[:check_out] || (Time.zone.today + 1.day),
      rooms_count: params[:rooms]&.to_i || 1,
      adults_count: params[:adults]&.to_i || 1,
      children_count: params[:children]&.to_i || 0,
      insurance_type: 'none',
      insurance_price: 0
    )
    
    @booking.calculate_total_price
    @insurance_options = InsuranceService.available_options(booking_class: 'HotelBooking')
  end

  def create
    @hotel = Hotel.find(params[:hotel_id])
    @hotel_room = @hotel.hotel_rooms.find(params[:hotel_booking][:hotel_room_id])
    
    @booking = HotelBooking.new(booking_params)
    @booking.hotel = @hotel
    @booking.hotel_room = @hotel_room
    @booking.user = Current.user if Current.user
    @booking.calculate_total_price
    
    # Process insurance if provided
    if params[:hotel_booking][:insurance_type].present?
      flow_service = BookingFlowService.new(@booking)
      flow_service.process_insurance(
        params[:hotel_booking][:insurance_type],
        trip_type: :single,
        trip_count: 1
      )
    end
    
    # Lock the room for 10 minutes
    flow_service = BookingFlowService.new(@booking)
    unless flow_service.lock_resource
      flash.now[:alert] = '房间锁定失败，请重试'
      @insurance_options = InsuranceService.available_options(booking_class: 'HotelBooking')
      render :new, status: :unprocessable_entity
      return
    end
    
    if @booking.save
      redirect_to hotel_booking_path(@booking)
    else
      @insurance_options = InsuranceService.available_options(booking_class: 'HotelBooking')
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = HotelBooking.find(params[:id])
    @hotel = @booking.hotel
    @hotel_room = @booking.hotel_room
    
    # Check if room lock has expired
    if BookingFlowService.lock_expired?(@booking) && @booking.status == 'pending'
      flash[:alert] = '订单已过期，请重新预订'
      redirect_to hotel_path(@hotel)
    end
  end

  def pay
    @booking = HotelBooking.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Just process the payment
    flow_service = BookingFlowService.new(@booking)
    if flow_service.complete_payment
      render json: { success: true }
    else
      render json: { success: false, message: flow_service.errors.join(', ') }, status: :unprocessable_entity
    end
  end

  def success
    @booking = HotelBooking.find(params[:id])
    @hotel = @booking.hotel
  end

  private
  
  def booking_params
    params.require(:hotel_booking).permit(
      :hotel_room_id,
      :check_in_date,
      :check_out_date,
      :rooms_count,
      :adults_count,
      :children_count,
      :guest_name,
      :guest_phone,
      :payment_method,
      :coupon_code,
      :special_requests,
      :insurance_type,
      :insurance_price
    )
  end
end
