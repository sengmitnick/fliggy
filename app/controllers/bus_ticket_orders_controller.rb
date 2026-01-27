class BusTicketOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @bus_ticket = BusTicket.find(params[:bus_ticket_id])
    @insurance_type = params[:insurance_type] || 'none'
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :asc)
    
    # Get user's contacts for quick selection
    @contacts = current_user.contacts.order(is_default: :desc, created_at: :desc).limit(10)
    
    # Get default contact for pre-filling
    default_contact = current_user.contacts.find_by(is_default: true)
    @default_contact_phone = default_contact&.phone || current_user.phone || ''
    
    # Restore selected passenger IDs from URL params
    @selected_passenger_ids = params[:selected_passenger_ids]&.split(',') || []
    
    # Calculate insurance price
    @insurance_price = case @insurance_type
    when 'refund'
      9
    when 'premium'
      3
    else
      0
    end
    
    # Calculate total (base + insurance)
    @base_price = @bus_ticket.price.to_i
    @total_price = @base_price + @insurance_price
  end


  def create
    @bus_ticket = BusTicket.find(params[:bus_ticket_order][:bus_ticket_id])
    passenger_ids = params[:bus_ticket_order][:passenger_ids] || []
    
    if passenger_ids.empty?
      render json: { success: false, message: '请至少选择一位乘车人' }, status: :unprocessable_entity
      return
    end
    
    # Calculate prices
    insurance_type = params[:bus_ticket_order][:insurance_type] || 'none'
    base_price = @bus_ticket.price
    insurance_price_per_person = case insurance_type
    when 'refund' then 9
    when 'premium' then 3
    else 0
    end
    
    passenger_count = passenger_ids.length
    total_insurance_price = insurance_price_per_person * passenger_count
    total_price = (base_price * passenger_count) + total_insurance_price
    
    # Create one order with multiple passengers
    order = BusTicketOrder.new(
      user: current_user,
      bus_ticket: @bus_ticket,
      departure_station: @bus_ticket.departure_station,
      arrival_station: @bus_ticket.arrival_station,
      base_price: base_price,
      passenger_count: passenger_count,
      insurance_type: insurance_type,
      insurance_price: total_insurance_price,
      total_price: total_price,
      status: 'pending'
    )
    
    BusTicketOrder.transaction do
      if order.save
        # Create passenger records
        passenger_ids.each do |passenger_id|
          passenger = current_user.passengers.find(passenger_id)
          order.passengers.create!(
            passenger_name: passenger.name,
            passenger_id_number: passenger.id_number,
            insurance_type: insurance_type
          )
        end
        
        render json: { 
          success: true, 
          order_id: order.id,
          payment_url: pay_bus_ticket_order_path(order),
          success_url: success_bus_ticket_order_path(order)
        }
      else
        render json: { success: false, message: order.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end


  def pay
    @order = current_user.bus_ticket_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Update order status to paid
    if @order.update(status: 'paid')
      render json: { success: true }
    else
      render json: { success: false, message: '支付失败' }, status: :unprocessable_entity
    end
  end
  
  def success
    @order = current_user.bus_ticket_orders.find(params[:id])
    @bus_ticket = @order.bus_ticket
  end

  def destroy
    # Write your real logic here
  end

  private
  # Write your private methods here
end
