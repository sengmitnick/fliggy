class VisaOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_visa_product, only: [:new]
  before_action :set_visa_order, only: [:show, :pay]

  def new
    @visa_product = VisaProduct.friendly.find(params[:visa_product_id])
    @country = @visa_product.country
    @insurance_type = params[:insurance_type] || 'none'
    @traveler_count = params[:traveler_count]&.to_i || 1
    
    # Calculate insurance price
    @insurance_price = case @insurance_type
    when 'basic'
      50
    when 'premium'
      100
    else
      0
    end
    
    # Calculate total
    @unit_price = @visa_product.price.to_f
    @total_price = (@unit_price * @traveler_count) + @insurance_price
    
    # Get user's default contact info
    @contact_name = current_user.passengers.first&.name || ''
    @contact_phone = current_user.passengers.first&.phone || ''
    @delivery_address = '' # 用户需要手动输入邮寄地址
  end

  def create
    @visa_product = VisaProduct.find(params[:visa_order][:visa_product_id])
    
    @visa_order = VisaOrder.new(visa_order_params)
    @visa_order.user = current_user
    @visa_order.visa_product = @visa_product
    @visa_order.status = 'pending'
    @visa_order.payment_status = 'unpaid'
    
    if @visa_order.save
      render json: { 
        success: true, 
        order_id: @visa_order.id,
        payment_url: pay_visa_order_path(@visa_order),
        success_url: success_visa_order_path(@visa_order)
      }
    else
      render json: { success: false, message: @visa_order.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def show
    @visa_product = @visa_order.visa_product
    @country = @visa_product.country
    @travelers = @visa_order.visa_order_travelers
  end

  def pay
    # Password already verified by frontend via /profile/verify_pay_password
    # Update order status to paid
    if @visa_order.update(status: 'paid', payment_status: 'paid', paid_at: Time.current)
      render json: { success: true }
    else
      render json: { success: false, message: '支付失败' }, status: :unprocessable_entity
    end
  end

  def success
    @visa_order = current_user.visa_orders.find(params[:id])
    @visa_product = @visa_order.visa_product
    @country = @visa_product.country
    @travelers = @visa_order.visa_order_travelers
  end

  def destroy
    # Write your real logic here
  end

  private
  
  def set_visa_product
    @visa_product = VisaProduct.friendly.find(params[:visa_product_id])
  end
  
  def set_visa_order
    @visa_order = current_user.visa_orders.find(params[:id])
  end
  
  def visa_order_params
    params.require(:visa_order).permit(
      :visa_product_id, :traveler_count, :total_price,
      :delivery_address, :contact_name, :contact_phone,
      :insurance_type, :insurance_price
    )
  end
end
