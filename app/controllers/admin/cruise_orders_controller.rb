class Admin::CruiseOrdersController < Admin::BaseController
  before_action :set_cruise_order, only: [:show, :edit, :update, :destroy]

  def index
    @cruise_orders = CruiseOrder.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @cruise_order = CruiseOrder.new
  end

  def create
    @cruise_order = CruiseOrder.new(cruise_order_params)

    if @cruise_order.save
      redirect_to admin_cruise_order_path(@cruise_order), notice: 'Cruise order was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cruise_order.update(cruise_order_params)
      redirect_to admin_cruise_order_path(@cruise_order), notice: 'Cruise order was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cruise_order.destroy
    redirect_to admin_cruise_orders_path, notice: 'Cruise order was successfully deleted.'
  end

  private

  def set_cruise_order
    @cruise_order = CruiseOrder.find(params[:id])
  end

  def cruise_order_params
    params.require(:cruise_order).permit(:quantity, :total_price, :passenger_info, :contact_name, :contact_phone, :insurance_type, :insurance_price, :order_number, :accept_terms, :data_version, :status, :user_id, :cruise_product_id)
  end
end
