class ActivityOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_activity, only: [:new, :create]
  before_action :set_order, only: [:show, :pay, :success]

  def new
    @order = ActivityOrder.new(attraction_activity: @activity, quantity: 1)
    @attraction = @activity.attraction
    @visit_date = params[:visit_date]&.to_date || Date.tomorrow
    
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
  end

  def create
    if params[:activity_order][:passenger_ids].blank?
      respond_to do |format|
        format.html do
          redirect_to new_attraction_activity_activity_order_path(@activity), alert: '请选择出行人'
        end
        format.json { render json: { success: false, errors: ['请选择出行人'] }, status: :unprocessable_entity }
      end
      return
    end
    
    @order = current_user.activity_orders.build(activity_order_params)
    @order.attraction_activity = @activity
    
    if params[:activity_order][:insurance_type].present?
      @order.insurance_type = params[:activity_order][:insurance_type]
    end
    
    @order.total_price = params[:activity_order][:total_price].to_i if params[:activity_order][:total_price].present?
    
    if @order.save
      respond_to do |format|
        format.html { redirect_to activity_order_path(@order), notice: '订单创建成功，请完成支付' }
        format.json { render json: { success: true, order_id: @order.id, pay_url: pay_activity_order_path(@order), success_url: success_activity_order_path(@order) }, status: :created }
      end
    else
      @attraction = @activity.attraction
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      @visit_date = params[:activity_order][:visit_date]&.to_date || Date.tomorrow
      
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @activity = @order.attraction_activity
    @attraction = @activity.attraction
  end

  def pay
    @order.update!(status: 'paid')
    
    respond_to do |format|
      format.html { redirect_to success_activity_order_path(@order), notice: '支付成功' }
      format.json { render json: { success: true, order_id: @order.id, success_url: success_activity_order_path(@order) } }
    end
  end

  def success
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
    params.require(:activity_order).permit(:contact_phone, :visit_date, :quantity, :notes, :insurance_type, :total_price, passenger_ids: [])
  end
end
