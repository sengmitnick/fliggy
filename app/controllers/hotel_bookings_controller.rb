class HotelBookingsController < ApplicationController

  def new
    @hotel = Hotel.find(params[:hotel_id])
    @hotel_room = @hotel.hotel_rooms.find(params[:room_id])
    
    @booking = HotelBooking.new(
      hotel: @hotel,
      hotel_room: @hotel_room,
      check_in_date: params[:check_in] || Date.today,
      check_out_date: params[:check_out] || (Date.today + 1.day),
      rooms_count: params[:rooms]&.to_i || 1,
      adults_count: params[:adults]&.to_i || 1,
      children_count: params[:children]&.to_i || 0
    )
    
    @booking.calculate_total_price
  end

  def create
    @hotel = Hotel.find(params[:hotel_id])
    @hotel_room = @hotel.hotel_rooms.find(params[:hotel_booking][:hotel_room_id])
    
    @booking = HotelBooking.new(booking_params)
    @booking.hotel = @hotel
    @booking.hotel_room = @hotel_room
    @booking.user = Current.user if Current.user
    @booking.calculate_total_price
    
    if @booking.save
      redirect_to success_hotel_booking_path(@booking)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = HotelBooking.find(params[:id])
    @hotel = @booking.hotel
    @hotel_room = @booking.hotel_room
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
      :special_requests
    )
  end
end
