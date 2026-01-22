class CruiseOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    # 获取选中的商家产品
    @product = CruiseProduct.find(params[:product_id])
    @sailing = @product.cruise_sailing
    @cabin_type = @product.cabin_type
    @cruise_ship = @sailing.cruise_ship
    
    # Get user's contacts for quick selection
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc).limit(10)
    
    # 初始化订单对象，默认使用默认联系人信息，如果没有则使用当前用户信息
    default_contact = current_user.contacts.find_by(is_default: true)
    
    @cruise_order = current_user.cruise_orders.build(
      cruise_product: @product,
      quantity: @product.occupancy_requirement, # 默认人数
      contact_name: default_contact&.name || current_user.name,
      contact_phone: default_contact&.phone || current_user.phone,
      contact_email: default_contact&.email || current_user.email
    )
  end

  def create
    @product = CruiseProduct.find(params[:cruise_order][:cruise_product_id])
    @sailing = @product.cruise_sailing
    @cruise_ship = @sailing.cruise_ship
    
    @cruise_order = current_user.cruise_orders.build(cruise_order_params)
    @cruise_order.cruise_product = @product
    
    if @cruise_order.save
      # 转到确认页
      redirect_to confirm_cruise_order_path(@cruise_order)
    else
      # 返回表单页，显示错误
      @cabin_type = @product.cabin_type
      @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc).limit(10)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @cruise_order = current_user.cruise_orders.find(params[:id])
    @product = @cruise_order.cruise_product
    @sailing = @product.cruise_sailing
    @cabin_type = @product.cabin_type
    @cruise_ship = @sailing.cruise_ship
    @route = @sailing.cruise_route
  end

  def confirm
    @cruise_order = current_user.cruise_orders.find(params[:id])
    @product = @cruise_order.cruise_product
    @sailing = @product.cruise_sailing
    @cabin_type = @product.cabin_type
    @cruise_ship = @sailing.cruise_ship
  end

  def pay
    @cruise_order = current_user.cruise_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    @cruise_order.update!(status: 'paid')
    
    respond_to do |format|
      format.html { redirect_to payment_success_cruise_order_path(@cruise_order), notice: '支付成功' }
      format.json { render json: { success: true, order_id: @cruise_order.id, success_url: payment_success_cruise_order_path(@cruise_order) } }
    end
  end

  def payment_success
    @cruise_order = current_user.cruise_orders.find(params[:id])
    @cruise_ship = @cruise_order.cruise_product.cruise_sailing.cruise_ship
    
    # 更新订单状态为已支付
    if @cruise_order.pending_status?
      @cruise_order.update(status: 'paid')
      @cruise_order.create_order_notification
    end
  end

  private
  
  def cruise_order_params
    params.require(:cruise_order).permit(
      :cruise_product_id,
      :quantity,
      :contact_name,
      :contact_phone,
      :contact_email,
      :insurance_price,
      :remark,
      :accept_terms,
      passenger_info: {}
    )
  end
end
