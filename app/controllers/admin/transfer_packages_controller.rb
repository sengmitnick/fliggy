class Admin::TransferPackagesController < Admin::BaseController
  before_action :set_transfer_package, only: [:show, :edit, :update, :destroy]

  def index
    @transfer_packages = TransferPackage.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @transfer_package = TransferPackage.new
  end

  def create
    @transfer_package = TransferPackage.new(transfer_package_params)

    if @transfer_package.save
      redirect_to admin_transfer_package_path(@transfer_package), notice: 'Transfer package was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transfer_package.update(transfer_package_params)
      redirect_to admin_transfer_package_path(@transfer_package), notice: 'Transfer package was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transfer_package.destroy
    redirect_to admin_transfer_packages_path, notice: 'Transfer package was successfully deleted.'
  end

  private

  def set_transfer_package
    @transfer_package = TransferPackage.find(params[:id])
  end

  def transfer_package_params
    params.require(:transfer_package).permit(:name, :vehicle_category, :seats, :luggage, :wait_time, :refund_policy, :price, :original_price, :discount_amount, :features, :provider, :priority, :is_active)
  end
end
