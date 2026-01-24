class Admin::CharterBookingsController < Admin::BaseController
  before_action :set_charter_booking, only: [:show, :edit, :update, :destroy]

  def index
    @charter_bookings = CharterBooking.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @charter_booking = CharterBooking.new
  end

  def create
    @charter_booking = CharterBooking.new(charter_booking_params)

    if @charter_booking.save
      redirect_to admin_charter_booking_path(@charter_booking), notice: 'Charter booking was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @charter_booking.update(charter_booking_params)
      redirect_to admin_charter_booking_path(@charter_booking), notice: 'Charter booking was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @charter_booking.destroy
    redirect_to admin_charter_bookings_path, notice: 'Charter booking was successfully deleted.'
  end

  private

  def set_charter_booking
    @charter_booking = CharterBooking.find(params[:id])
  end

  def charter_booking_params
    params.require(:charter_booking).permit(:departure_date, :departure_time, :duration_hours, :booking_mode, :contact_name, :contact_phone, :passengers_count, :note, :total_price, :status, :order_number, :paid_at, :user_id, :charter_route_id, :vehicle_type_id)
  end
end
