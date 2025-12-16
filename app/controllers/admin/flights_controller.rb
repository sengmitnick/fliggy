class Admin::FlightsController < Admin::BaseController
  before_action :set_flight, only: [:show, :edit, :update, :destroy]

  def index
    @flights = Flight.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @flight = Flight.new
  end

  def create
    @flight = Flight.new(flight_params)

    if @flight.save
      redirect_to admin_flight_path(@flight), notice: 'Flight was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @flight.update(flight_params)
      redirect_to admin_flight_path(@flight), notice: 'Flight was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @flight.destroy
    redirect_to admin_flights_path, notice: 'Flight was successfully deleted.'
  end

  private

  def set_flight
    @flight = Flight.find(params[:id])
  end

  def flight_params
    params.require(:flight).permit(:departure_city, :destination_city, :departure_time, :arrival_time, :departure_airport, :arrival_airport, :airline, :flight_number, :aircraft_type, :price, :discount_price, :seat_class, :available_seats, :flight_date)
  end
end
