class MembershipOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :destroy]

  def index
    @orders = current_user.membership_orders.recent.page(params[:page]).per(20)
  end

  def new
    @product = MembershipProduct.friendly.find(params[:product_id])
    @order = MembershipOrder.new(
      membership_product: @product,
      quantity: params[:quantity]&.to_i || 1
    )
    
    # Get default address or create blank one
    @address = current_user.addresses.find_by(is_default: true) || Address.new
    @user_mileage = current_user.available_mileage
  end

  def create
    @product = MembershipProduct.find(params[:membership_order][:membership_product_id])
    
    # Check stock
    if !@product.in_stock?
      redirect_to membership_product_path(@product), alert: '商品已售罄'
      return
    end
    
    @order = current_user.membership_orders.build(order_params)
    @order.membership_product = @product
    
    # Calculate totals based on quantity
    quantity = @order.quantity
    @order.total_cash = @product.price_cash * quantity
    @order.total_mileage = @product.price_mileage * quantity
    
    # Check if user has enough balance and mileage
    if @order.total_cash > current_user.balance
      redirect_to new_membership_order_path(product_id: @product.id, quantity: quantity), alert: '余额不足'
      return
    end
    
    if @order.total_mileage > current_user.available_mileage
      redirect_to new_membership_order_path(product_id: @product.id, quantity: quantity), alert: '里程不足'
      return
    end
    
    if @order.save
      # Deduct balance and mileage
      current_user.deduct_balance(@order.total_cash) if @order.total_cash > 0
      current_user.deduct_mileage(@order.total_mileage) if @order.total_mileage > 0
      
      # Update order status
      @order.update(status: 'paid')
      
      # Update product stock and sales
      if @product.stock.present?
        @product.update(stock: @product.stock - quantity)
      end
      @product.update(sales_count: @product.sales_count + quantity)
      
      redirect_to success_membership_order_path(@order)
    else
      @address = Address.new(order_params.slice(:contact_name, :contact_phone, :shipping_address))
      @user_mileage = current_user.available_mileage
      render :new
    end
  end

  def show
    # Show order details
  end

  def destroy
    if @order.can_cancel?
      # Refund balance and mileage
      current_user.add_balance(@order.total_cash) if @order.total_cash > 0
      current_user.add_mileage(@order.total_mileage) if @order.total_mileage > 0
      
      # Restore product stock
      if @order.membership_product.stock.present?
        @order.membership_product.update(stock: @order.membership_product.stock + @order.quantity)
      end
      
      @order.update(status: 'cancelled')
      redirect_to membership_orders_path, notice: '订单已取消'
    else
      redirect_to membership_order_path(@order), alert: '该订单不能取消'
    end
  end

  def success
    @order = current_user.membership_orders.find(params[:id])
  end

  private
  
  def set_order
    @order = current_user.membership_orders.find(params[:id])
  end
  
  def order_params
    params.require(:membership_order).permit(
      :membership_product_id,
      :quantity,
      :contact_name,
      :contact_phone,
      :shipping_address,
      :notes
    )
  end
end
