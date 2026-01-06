class CarOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @car = Car.find(params[:car_id])
  end

  def create
    @car = Car.find(params[:car_order][:car_id])
    @car_order = current_user.car_orders.build(car_order_params)
    @car_order.car = @car
    
    if @car_order.save
      redirect_to car_order_path(@car_order), notice: '订单创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @car_order = current_user.car_orders.find(params[:id])
    @car = @car_order.car
  end

  def pay
    @car_order = current_user.car_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    @car_order.update!(status: 'paid')
    
    render json: { success: true }
  end

  def success
    @car_order = current_user.car_orders.find(params[:id])
    @car = @car_order.car
  end

  private

  def car_order_params
    params.require(:car_order).permit(
      :car_id,
      :driver_name, 
      :driver_id_number, 
      :contact_phone, 
      :pickup_datetime, 
      :return_datetime, 
      :pickup_location,
      :total_price
    )
  end
end
