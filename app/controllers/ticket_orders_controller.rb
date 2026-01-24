class TicketOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [:new, :create]
  before_action :set_order, only: [:show, :pay, :success]

  def new
    @order = TicketOrder.new(ticket: @ticket, quantity: 1)
    @attraction = @ticket.attraction
    @supplier_id = params[:supplier_id]
    @visit_date = params[:visit_date]&.to_date || Date.tomorrow
    
    # 获取当前用户的所有出行人
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    
    # 如果指定了供应商，获取供应商信息和价格
    if @supplier_id.present?
      @supplier = Supplier.find(@supplier_id)
      @ticket_supplier = TicketSupplier.find_by(ticket_id: @ticket.id, supplier_id: @supplier_id)
    end
  end

  def create
    # Handle passenger_ids array if provided
    if params[:ticket_order][:passenger_ids].present?
      # Already an array, no need to process
    elsif params[:ticket_order][:passenger_id] == "new" && params[:new_passenger].present?
      # Handle new passenger creation (legacy support)
      passenger_id = params[:ticket_order][:passenger_id]
      new_passenger = current_user.passengers.build(new_passenger_params)
      unless new_passenger.save
        @order = current_user.ticket_orders.build(ticket_order_params)
        @order.ticket = @ticket
        @attraction = @ticket.attraction
        @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
        error_message = "出行人信息有误：#{new_passenger.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.html do
            @order.errors.add(:base, error_message)
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { success: false, errors: [error_message] }, status: :unprocessable_entity }
        end
        return
      end
      params[:ticket_order][:passenger_ids] = [new_passenger.id.to_s]
    elsif params[:ticket_order][:passenger_id].present?
      # Convert single passenger_id to array
      params[:ticket_order][:passenger_ids] = [params[:ticket_order][:passenger_id]]
    end
    
    @order = current_user.ticket_orders.build(ticket_order_params)
    @order.ticket = @ticket
    # Store insurance info if provided
    if params[:ticket_order][:insurance_type].present?
      @order.insurance_type = params[:ticket_order][:insurance_type]
      @order.insurance_price = params[:ticket_order][:insurance_price].to_i
    end
    # Set total price
    @order.total_price = params[:ticket_order][:total_price].to_i if params[:ticket_order][:total_price].present?
    
    if @order.save
      respond_to do |format|
        format.html { redirect_to ticket_order_path(@order), notice: '订单创建成功，请完成支付' }
        format.json { render json: { success: true, order_id: @order.id, pay_url: pay_ticket_order_path(@order), success_url: success_ticket_order_path(@order) }, status: :created }
      end
    else
      @attraction = @ticket.attraction
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      @supplier_id = params[:ticket_order][:supplier_id]
      @visit_date = params[:ticket_order][:visit_date]&.to_date || Date.tomorrow
      
      if @supplier_id.present?
        @supplier = Supplier.find(@supplier_id)
        @ticket_supplier = TicketSupplier.find_by(ticket_id: @ticket.id, supplier_id: @supplier_id)
      end
      
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    @ticket = @order.ticket
    @attraction = @ticket.attraction
    @supplier = @order.supplier
    @passenger = @order.passenger
  end

  def pay
    @order = current_user.ticket_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    @order.update!(status: 'paid')
    
    respond_to do |format|
      format.html { redirect_to success_ticket_order_path(@order), notice: '支付成功' }
      format.json { render json: { success: true, order_id: @order.id, success_url: success_ticket_order_path(@order) } }
    end
  end

  def success
    @order = current_user.ticket_orders.find(params[:id])
    @ticket = @order.ticket
    @attraction = @ticket.attraction
    @passenger = @order.passenger
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_order
    @order = current_user.ticket_orders.find(params[:id])
  end

  def ticket_order_params
    params.require(:ticket_order).permit(:contact_phone, :visit_date, :quantity, :notes, :supplier_id, :passenger_id, :insurance_type, :insurance_price, :total_price, passenger_ids: [])
  end

  def new_passenger_params
    params.require(:new_passenger).permit(:name, :id_number, :phone, :id_type, :is_self)
  end
end
