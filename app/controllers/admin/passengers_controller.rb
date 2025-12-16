class Admin::PassengersController < Admin::BaseController
  before_action :set_passenger, only: [:show, :edit, :update, :destroy]

  def index
    @passengers = Passenger.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @passenger = Passenger.new
  end

  def create
    @passenger = Passenger.new(passenger_params)

    if @passenger.save
      redirect_to admin_passenger_path(@passenger), notice: 'Passenger was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @passenger.update(passenger_params)
      redirect_to admin_passenger_path(@passenger), notice: 'Passenger was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @passenger.destroy
    redirect_to admin_passengers_path, notice: 'Passenger was successfully deleted.'
  end

  private

  def set_passenger
    @passenger = Passenger.find(params[:id])
  end

  def passenger_params
    params.require(:passenger).permit(:name, :id_type, :id_number, :phone, :user_id)
  end
end
