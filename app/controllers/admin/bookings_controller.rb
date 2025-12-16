class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    @bookings = Booking.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @booking = Booking.new
  end

  def create
    @booking = Booking.new(booking_params)

    if @booking.save
      redirect_to admin_booking_path(@booking), notice: 'Booking was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @booking.update(booking_params)
      redirect_to admin_booking_path(@booking), notice: 'Booking was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy
    redirect_to admin_bookings_path, notice: 'Booking was successfully deleted.'
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:passenger_name, :passenger_id_number, :contact_phone, :total_price, :accept_terms, :insurance_type, :insurance_price, :status, :user_id, :flight_id)
  end
end
