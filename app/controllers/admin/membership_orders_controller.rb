class Admin::MembershipOrdersController < Admin::BaseController
  before_action :set_membership_order, only: [:show, :edit, :update, :destroy]

  def index
    @membership_orders = MembershipOrder.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @membership_order = MembershipOrder.new
  end

  def create
    @membership_order = MembershipOrder.new(membership_order_params)

    if @membership_order.save
      redirect_to admin_membership_order_path(@membership_order), notice: 'Membership order was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @membership_order.update(membership_order_params)
      redirect_to admin_membership_order_path(@membership_order), notice: 'Membership order was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @membership_order.destroy
    redirect_to admin_membership_orders_path, notice: 'Membership order was successfully deleted.'
  end

  private

  def set_membership_order
    @membership_order = MembershipOrder.find(params[:id])
  end

  def membership_order_params
    params.require(:membership_order).permit(:quantity, :price_cash, :price_mileage, :total_cash, :total_mileage, :status, :order_number, :shipping_address, :contact_phone, :contact_name, :notes, :user_id, :membership_product_id)
  end
end
