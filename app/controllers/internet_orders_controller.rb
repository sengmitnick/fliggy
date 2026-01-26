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
    @order.status = 'pending'
    
    if @order.save
      respond_to do |format|
        format.json {
          render json: { 
            success: true, 
            order_id: @order.id,
            payment_url: pay_internet_order_path(@order),
            success_url: success_internet_order_path(@order)
          }
        }
        format.html {
          redirect_to success_internet_order_path(@order)
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: { success: false, message: @order.errors.full_messages.join(', ') }, status: :unprocessable_entity
        }
        format.html {
          load_orderable
          @addresses = current_user.addresses.delivery
          @passengers = current_user.passengers
          render :new, status: :unprocessable_entity
        }
      end
    end
  end

  def pay
    @order = current_user.internet_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Update order status to paid
    if @order.update(status: 'paid')
      render json: { success: true }
    else
      render json: { success: false, message: '支付失败' }, status: :unprocessable_entity
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
