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
    # 如果 URL 包含参数（从确认页返回），则使用 URL 参数恢复表单状态
    default_contact = current_user.contacts.find_by(is_default: true)
    
    @cruise_order = current_user.cruise_orders.build(
      cruise_product: @product,
      quantity: params[:quantity] || @product.occupancy_requirement,
      contact_name: params[:contact_name] || default_contact&.name || current_user.name,
      contact_phone: params[:contact_phone] || default_contact&.phone || current_user.phone,
      contact_email: params[:contact_email] || default_contact&.email || current_user.email,
      insurance_type: params[:insurance_type] || 'none',
      insurance_price: params[:insurance_price] || 0,
      remark: params[:remark]
    )
  end

  def create
    @product = CruiseProduct.find(params[:cruise_order][:cruise_product_id])
    @sailing = @product.cruise_sailing
    @cruise_ship = @sailing.cruise_ship
    
    @cruise_order = current_user.cruise_orders.build(cruise_order_params)
    @cruise_order.cruise_product = @product
    
    if @cruise_order.save
      # 检测 AJAX 请求（Rails UJS 带有 X-Requested-With header）
      if request.xhr?
        render json: { 
          success: true, 
          order_id: @cruise_order.id,
          amount: @cruise_order.total_price.to_f,
          payment_url: pay_cruise_order_path(@cruise_order),
          success_url: payment_success_cruise_order_path(@cruise_order)
        }
      else
        redirect_to confirm_cruise_order_path(@cruise_order)
      end
    else
      # 验证失败，也需要区分 AJAX 和普通请求
      if request.xhr?
        render json: { success: false, errors: @cruise_order.errors.full_messages }, status: :unprocessable_entity
      else
        @cabin_type = @product.cabin_type
        @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc).limit(10)
        render :new, status: :unprocessable_entity
      end
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
      :insurance_type,
      :remark,
      :accept_terms,
      :passenger_info
    )
  end
end
