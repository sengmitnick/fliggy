class InsuranceOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :pay, :success, :cancel, :destroy]

  def my_orders
    @orders = current_user.insurance_orders
      .includes(:insurance_product)
      .recent
      .page(params[:page])
      .per(10)

    # Filter by status
    if params[:status].present?
      @orders = @orders.where(status: params[:status])
    end
  end

  def new
    @product = InsuranceProduct.find(params[:insurance_product_id])
    
    # Load user contacts
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc)
    @default_contact = @contacts.find_by(is_default: true) || @contacts.first
    
    # Load user passengers (出行人列表)
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    @default_passenger = @passengers.find_by(is_self: true) || @passengers.first
    
    # Get dates and destination from params
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @destination = params[:destination]
    @destination_type = params[:destination_type] || @product.product_type
    @city_id = params[:city_id]
    
    # Find city if provided
    if @city_id.present?
      @city = City.find_by(id: @city_id)
    elsif @destination.present?
      @city = City.find_by(name: @destination)
      @city_id = @city&.id
    end
    
    # Calculate days and price (with city-specific pricing)
    if @start_date.present? && @end_date.present?
      start_date = Date.parse(@start_date) rescue nil
      end_date = Date.parse(@end_date) rescue nil
      
      if start_date && end_date
        @days = (end_date - start_date).to_i + 1
        @unit_price = @product.calculate_price(@days, city_id: @city_id)
      end
    end

    # Default insured person from current user (will be replaced by passenger selector)
    @insured_persons = [{ name: current_user.name.presence || current_user.email.split('@').first, id_number: '' }]
    
    @order = InsuranceOrder.new(
      insurance_product: @product,
      start_date: start_date,
      end_date: end_date,
      destination: @destination,
      destination_type: @destination_type,
      days: @days,
      unit_price: @unit_price,
      quantity: 1
    )
  end

  def create
    @product = InsuranceProduct.find(params[:insurance_order][:insurance_product_id])
    policyholder_id = params[:insurance_order][:policyholder_id]
    
    # Get policyholder (passenger) information
    insured_persons = []
    if policyholder_id.present?
      passenger = current_user.passengers.find_by(id: policyholder_id)
      if passenger
        insured_persons << {
          name: passenger.name,
          id_number: passenger.id_number
        }
      end
    end

    @order = current_user.insurance_orders.build(insurance_order_params)
    @order.insurance_product = @product
    @order.insured_persons = insured_persons
    @order.source = 'standalone'
    @order.quantity = insured_persons.size
    @order.status = 'pending'

    if @order.save
      redirect_to insurance_order_path(@order), notice: '保险订单创建成功，请完成支付'
    else
      # Load necessary variables for re-rendering the form
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Show order details
  end

  def pay
    # Process payment - check balance (password already verified by payment_confirmation_controller)
    required_amount = @order.total_price
    if @order.pending? && current_user.balance >= required_amount
      # Deduct balance
      current_user.update!(balance: current_user.balance - required_amount)
      
      # Update order status
      @order.update!(
        status: 'paid',
        paid_at: Time.current
      )
      
      render json: { success: true, message: '支付成功' }
    elsif !@order.pending?
      render json: { success: false, message: '订单状态异常' }, status: :unprocessable_entity
    else
      render json: { success: false, message: '余额不足，请先充值' }, status: :unprocessable_entity
    end
  end

  def success
    # Payment success page
  end

  def cancel
    if @order.can_cancel?
      @order.update!(status: 'cancelled')
      redirect_to my_orders_insurance_orders_path, notice: '订单已取消'
    else
      redirect_to insurance_order_path(@order), alert: '该订单不能取消'
    end
  end

  def destroy
    if @order.can_cancel?
      @order.destroy
      redirect_to my_orders_insurance_orders_path, notice: '订单已删除'
    else
      redirect_to insurance_order_path(@order), alert: '该订单不能删除'
    end
  end

  private

  def set_order
    @order = current_user.insurance_orders.find(params[:id])
  end

  def load_form_data
    # Load user contacts
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc)
    @default_contact = @contacts.find_by(is_default: true) || @contacts.first
    
    # Load user passengers
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    @default_passenger = @passengers.find_by(is_self: true) || @passengers.first
    
    # Get dates and destination from params
    @start_date = params[:insurance_order][:start_date]
    @end_date = params[:insurance_order][:end_date]
    @destination = params[:insurance_order][:destination]
    @destination_type = params[:insurance_order][:destination_type]
    @city_id = params[:city_id]
    
    # Find city if provided
    if @city_id.present?
      @city = City.find_by(id: @city_id)
    elsif @destination.present?
      @city = City.find_by(name: @destination)
      @city_id = @city&.id
    end
    
    # Calculate days and price
    if @start_date.present? && @end_date.present?
      start_date = Date.parse(@start_date) rescue nil
      end_date = Date.parse(@end_date) rescue nil
      
      if start_date && end_date
        @days = (end_date - start_date).to_i + 1
        @unit_price = @product.calculate_price(@days, city_id: @city_id)
      end
    end
  end

  def insurance_order_params
    params.require(:insurance_order).permit(
      :start_date,
      :end_date,
      :destination,
      :destination_type,
      :unit_price,
      :quantity
    )
  end
end
