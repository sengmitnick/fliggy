class Admin::VehicleTypesController < Admin::BaseController
  before_action :set_vehicle_type, only: [:show, :edit, :update, :destroy]

  def index
    @vehicle_types = VehicleType.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @vehicle_type = VehicleType.new
  end

  def create
    @vehicle_type = VehicleType.new(vehicle_type_params)

    if @vehicle_type.save
      redirect_to admin_vehicle_type_path(@vehicle_type), notice: 'Vehicle type was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vehicle_type.update(vehicle_type_params)
      redirect_to admin_vehicle_type_path(@vehicle_type), notice: 'Vehicle type was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @vehicle_type.destroy
    redirect_to admin_vehicle_types_path, notice: 'Vehicle type was successfully deleted.'
  end

  private

  def set_vehicle_type
    @vehicle_type = VehicleType.find(params[:id])
  end

  def vehicle_type_params
    params.require(:vehicle_type).permit(:name, :category, :level, :seats, :luggage_capacity, :hourly_price_6h, :hourly_price_8h, :included_mileage, :image_url)
  end
end
