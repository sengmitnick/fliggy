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
    
    # Calculate timeline stages based on processing_days
    total_days = @visa_product.processing_days
    @review_days = (total_days * 0.33).ceil  # 商家审核约占1/3
    @embassy_days = total_days - @review_days  # 使领馆处理占剩余时间
    @delivery_days = 0  # 寄回签证当天处理
    
    # Load user contacts
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc)
    @default_contact = @contacts.find_by(is_default: true) || @contacts.first
    
    # Get user's default contact info from contacts or passengers
    @contact_name = @default_contact&.name || current_user.passengers.first&.name || ''
    @contact_phone = @default_contact&.phone || current_user.passengers.first&.phone || ''
    
    # Load user addresses
    @addresses = current_user.addresses.delivery.order(is_default: :desc, created_at: :desc)
    @default_address = @addresses.find(&:is_default) || @addresses.first
    
    if @default_address
      @delivery_address = @default_address.full_address
      @contact_name = @default_address.name if @contact_name.blank?
      @contact_phone = @default_address.phone if @contact_phone.blank?
    else
      @delivery_address = ''
    end
  end

  def create
    @visa_product = VisaProduct.find(params[:visa_order][:visa_product_id])
    
    @visa_order = VisaOrder.new(visa_order_params)
    @visa_order.user = current_user
    @visa_order.visa_product = @visa_product
    @visa_order.unit_price = @visa_product.price
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
  
  # Helper methods for status display
  helper_method :status_color, :status_text, :payment_status_color, :payment_status_text
  
  def status_color(status)
    case status
    when 'pending'
      'text-orange-500'
    when 'paid'
      'text-blue-500'
    when 'processing'
      'text-purple-500'
    when 'completed'
      'text-green-500'
    when 'cancelled'
      'text-gray-500'
    else
      'text-gray-500'
    end
  end
  
  def status_text(status)
    case status
    when 'pending'
      '待支付'
    when 'paid'
      '已支付'
    when 'processing'
      '处理中'
    when 'completed'
      '已完成'
    when 'cancelled'
      '已取消'
    else
      status
    end
  end
  
  def payment_status_color(status)
    case status
    when 'unpaid'
      'text-orange-500'
    when 'paid'
      'text-green-500'
    when 'refunded'
      'text-gray-500'
    else
      'text-gray-500'
    end
  end
  
  def payment_status_text(status)
    case status
    when 'unpaid'
      '未支付'
    when 'paid'
      '已支付'
    when 'refunded'
      '已退款'
    else
      status
    end
  end
end
