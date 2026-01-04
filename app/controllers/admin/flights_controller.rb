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

  # Batch generator page
  def generator
    @cities = City.pluck(:name).sort
  end

  # Batch generate flights
  def batch_generate
    departure_city = params[:departure_city]
    destination_city = params[:destination_city]
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    if departure_city.blank? || destination_city.blank?
      redirect_to generator_admin_flights_path, alert: '请选择出发城市和目的城市'
      return
    end

    if start_date > end_date
      redirect_to generator_admin_flights_path, alert: '开始日期不能晚于结束日期'
      return
    end

    total_flights = 0
    (start_date..end_date).each do |date|
      flights = Flight.generate_for_route(departure_city, destination_city, date)
      total_flights += flights.count
    end

    redirect_to admin_flights_path, notice: "成功生成 #{total_flights} 个航班 (#{departure_city} → #{destination_city}, #{start_date} 至 #{end_date})"
  rescue ArgumentError => e
    redirect_to generator_admin_flights_path, alert: "日期格式错误: #{e.message}"
  end

  private

  def set_flight
    @flight = Flight.find(params[:id])
  end

  def flight_params
    params.require(:flight).permit(:departure_city, :destination_city, :departure_time, :arrival_time, :departure_airport, :arrival_airport, :airline, :flight_number, :aircraft_type, :price, :discount_price, :seat_class, :available_seats, :flight_date)
  end
end
