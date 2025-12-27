class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_flight, only: [:new, :create]

  def index
    @bookings = current_user.bookings.includes(:flight).order(created_at: :desc)
    
    # 根据状态筛选
    if params[:status].present?
      @bookings = @bookings.where(status: params[:status])
    end
    
    @bookings = @bookings.page(params[:page]).per(10)
  end

  def new
    @booking = Booking.new
    @passengers = current_user.passengers
    @selected_offer = @flight.flight_offers.find_by(id: params[:offer_id]) if params[:offer_id]
  end

  def create
    @booking = current_user.bookings.build(booking_params)
    @booking.flight = @flight
    
    # 计算总价
    offer = @flight.flight_offers.find_by(id: params[:booking][:offer_id])
    @booking.total_price = offer&.price || @flight.price
    
    if @booking.save
      redirect_to booking_path(@booking), notice: '订单创建成功'
    else
      @passengers = current_user.passengers
      @selected_offer = offer
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.bookings.find(params[:id])
    @flight = @booking.flight
  end

  def cancel
    @booking = current_user.bookings.find(params[:id])
    @booking.update!(status: :cancelled)
    redirect_to flights_path, notice: '订单已取消'
  end

  def pay
    @booking = current_user.bookings.find(params[:id])
    @booking.update!(status: :paid)
    render json: { success: true }
  end

  def success
    @booking = current_user.bookings.find(params[:id])
    @flight = @booking.flight
  end

  private

  def set_flight
    @flight = Flight.find(params[:flight_id])
  end

  def booking_params
    params.require(:booking).permit(:passenger_name, :passenger_id_number, :contact_phone, :accept_terms, :insurance_type, :insurance_price)
  end
end
