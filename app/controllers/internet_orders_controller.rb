class InternetOrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.internet_orders.order(created_at: :desc)
  end

  def new
    @order = current_user.internet_orders.build
    load_orderable
    @addresses = current_user.addresses.delivery
    @passengers = current_user.passengers
  end

  def create
    @order = current_user.internet_orders.build(order_params)
    
    if @order.save
      # 模拟支付流程，实际应该跳转到支付页面
      @order.update(status: 'paid')
      redirect_to success_internet_order_path(@order)
    else
      load_orderable
      @addresses = current_user.addresses.delivery
      @passengers = current_user.passengers
      render :new, status: :unprocessable_entity
    end
  end

  def success
    @order = current_user.internet_orders.find(params[:id])
  end

  private

  def order_params
    params.require(:internet_order).permit(
      :orderable_id, :orderable_type, :order_type, :region, 
      :quantity, :total_price, :delivery_method,
      delivery_info: [:address_id, :name, :phone, :full_address],
      contact_info: [:name, :phone, :passenger_id],
      rental_info: [:pickup_date, :return_date, :pickup_location, :days]
    )
  end

  def load_orderable
    if params[:orderable_type] && params[:orderable_id]
      @orderable = params[:orderable_type].constantize.find(params[:orderable_id])
    end
  end
end
