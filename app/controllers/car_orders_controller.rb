class CarOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @car = Car.find(params[:car_id])
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    
    # 获取搜索时选择的城市和地点信息
    @search_city = params[:city] || session_current_city
    @search_pickup_location = params[:pickup_location]
    @search_pickup_date = params[:pickup_date]
    @search_return_date = params[:return_date]
    
    # 计算总价
    pickup_date = @search_pickup_date.present? ? Date.parse(@search_pickup_date) : Date.today
    return_date = @search_return_date.present? ? Date.parse(@search_return_date) : (Date.today + 2.days)
    days_count = (return_date - pickup_date).to_i
    @total_price = (@car.price_per_day * days_count).round
  end

  def create
    @car = Car.find(params[:car_order][:car_id])
    @car_order = current_user.car_orders.build(car_order_params)
    @car_order.car = @car
    
    if @car_order.save
      respond_to do |format|
        format.html { redirect_to car_order_path(@car_order), notice: '订单创建成功' }
        format.json { render json: { success: true, order_id: @car_order.id, pay_url: pay_car_order_path(@car_order), success_url: success_car_order_path(@car_order) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @car_order.errors.full_messages }, status: :unprocessable_entity }
      end
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
    
    respond_to do |format|
      format.html { redirect_to success_car_order_path(@car_order), notice: '支付成功' }
      format.json { render json: { success: true, order_id: @car_order.id, success_url: success_car_order_path(@car_order) } }
    end
  end

  def success
    @car_order = current_user.car_orders.find(params[:id])
    @car = @car_order.car
  end
  
  private
  
  def session_current_city
    if session[:last_destination_slug].present?
      destination = Destination.friendly.find(session[:last_destination_slug])
      destination.name
    else
      '深圳'
    end
  rescue
    '深圳'
  end

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
