class ActivityOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:new, :create]
  before_action :set_order, only: [:show]

  def new
    @order = ActivityOrder.new(attraction_activity: @activity, quantity: 1)
    @attraction = @activity.attraction
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
  end

  def create
    @order = current_user.activity_orders.build(activity_order_params)
    @order.attraction_activity = @activity
    
    if @order.save
      redirect_to activity_order_path(@order), notice: '订单创建成功，请完成支付'
    else
      @attraction = @activity.attraction
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @activity = @order.attraction_activity
    @attraction = @activity.attraction
  end

  private

  def set_activity
    @activity = AttractionActivity.find(params[:attraction_activity_id])
  end

  def set_order
    @order = current_user.activity_orders.find(params[:id])
  end

  def activity_order_params
    params.require(:activity_order).permit(
      :visit_date, 
      :quantity, 
      :notes, 
      :insurance_type,
      :contact_phone,
      passenger_ids: []
    )
  end
end
