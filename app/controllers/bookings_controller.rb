class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_flight, only: [:new, :create]

  def index
    @status_filter = params[:status] || 'all'
    
    @bookings = current_user.bookings.includes(:flight, :return_flight)
                           .order(created_at: :desc)
    
    # Filter by status
    case @status_filter
    when 'pending'
      @bookings = @bookings.where(status: 'pending')
    when 'upcoming'
      @bookings = @bookings.where(status: ['paid', 'completed'])
                           .where('bookings.created_at >= ?', Date.today)
    when 'review'
      # 待评价状态 - 已完成但未评价的订单（未实现评价系统，暂时为空）
      @bookings = @bookings.none
    when 'refund'
      @bookings = @bookings.where(status: 'cancelled')
    end
    
    @bookings = @bookings.page(params[:page]).per(10)
  end

  def new
    @booking = Booking.new
    @passengers = current_user.passengers
    @selected_offer = @flight.flight_offers.find_by(id: params[:offer_id]) if params[:offer_id]
    @trip_type = params[:trip_type] || 'one_way'
    @return_flight = Flight.find_by(id: params[:return_flight_id]) if params[:return_flight_id]
    @return_offer = @return_flight.flight_offers.find_by(id: params[:return_offer_id]) if @return_flight && params[:return_offer_id]
  end

  def create
    @booking = current_user.bookings.build(booking_params)
    @booking.flight = @flight
    
    # 计算去程价格
    offer = @flight.flight_offers.find_by(id: params[:booking][:offer_id])
    @booking.total_price = offer&.price || @flight.price
    
    # Handle round-trip booking
    if params[:booking][:trip_type] == 'round_trip' && params[:booking][:return_flight_id].present?
      @booking.trip_type = 'round_trip'
      @booking.return_flight_id = params[:booking][:return_flight_id]
      @booking.return_date = Flight.find_by(id: params[:booking][:return_flight_id])&.flight_date
      
      # Add return flight price to total
      return_flight = Flight.find_by(id: params[:booking][:return_flight_id])
      if return_flight
        return_offer = return_flight.flight_offers.find_by(id: params[:booking][:return_offer_id])
        @booking.return_offer_id = return_offer&.id
        return_price = return_offer&.price || return_flight.price
        @booking.total_price += return_price
      end
      
      # 往返机票的保险费是双倍
      if params[:booking][:insurance_price].present?
        insurance_price = params[:booking][:insurance_price].to_f
        @booking.insurance_price = insurance_price * 2  # 往返双倍保险
      end
    else
      # 单程保险
      @booking.insurance_price = params[:booking][:insurance_price].to_f if params[:booking][:insurance_price].present?
    end
    
    if @booking.save
      redirect_to booking_path(@booking), notice: '订单创建成功'
    else
      @passengers = current_user.passengers
      @selected_offer = offer
      @trip_type = params[:booking][:trip_type] || 'one_way'
      @return_flight = Flight.find_by(id: params[:booking][:return_flight_id]) if params[:booking][:return_flight_id]
      @return_offer = @return_flight.flight_offers.find_by(id: params[:booking][:return_offer_id]) if @return_flight && params[:booking][:return_offer_id]
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
    params.require(:booking).permit(:passenger_name, :passenger_id_number, :contact_phone, :accept_terms, :insurance_type, :insurance_price, :trip_type, :return_flight_id, :return_date, :return_offer_id)
  end
end
