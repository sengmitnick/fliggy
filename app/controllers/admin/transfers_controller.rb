class Admin::TransfersController < Admin::BaseController
  before_action :set_transfer, only: [:show, :edit, :update, :destroy]

  def index
    @transfers = Transfer.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @transfer = Transfer.new
  end

  def create
    @transfer = Transfer.new(transfer_params)

    if @transfer.save
      redirect_to admin_transfer_path(@transfer), notice: 'Transfer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transfer.update(transfer_params)
      redirect_to admin_transfer_path(@transfer), notice: 'Transfer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transfer.destroy
    redirect_to admin_transfers_path, notice: 'Transfer was successfully deleted.'
  end

  private

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def transfer_params
    params.require(:transfer).permit(:transfer_type, :service_type, :location_from, :location_to, :pickup_datetime, :flight_number, :train_number, :passenger_name, :passenger_phone, :vehicle_type, :provider_name, :license_plate, :driver_name, :total_price, :discount_amount, :status, :driver_status, :user_id, :transfer_package_id, :flight_id, :train_id)
  end
end
