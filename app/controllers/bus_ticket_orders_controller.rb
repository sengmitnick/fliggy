class BusTicketOrdersController < ApplicationController
  before_action :authenticate_user!

  def new
    @bus_ticket = BusTicket.find(params[:bus_ticket_id])
    @insurance_type = params[:insurance_type] || 'none'
    @passengers = current_user.passengers
    
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
    
    # Create order for each passenger
    orders_created = []
    passenger_ids.each do |passenger_id|
      passenger = current_user.passengers.find(passenger_id)
      order = BusTicketOrder.new(
        user: current_user,
        bus_ticket: @bus_ticket,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        departure_station: @bus_ticket.departure_station,
        arrival_station: @bus_ticket.arrival_station,
        insurance_type: params[:bus_ticket_order][:insurance_type],
        insurance_price: params[:bus_ticket_order][:insurance_price].to_f / passenger_ids.length,
        total_price: params[:bus_ticket_order][:total_price].to_f / passenger_ids.length,
        status: 'pending'
      )
      
      if order.save
        orders_created << order
      else
        # Rollback: delete previously created orders
        orders_created.each(&:destroy)
        render json: { success: false, message: order.errors.full_messages.join(', ') }, status: :unprocessable_entity
        return
      end
    end
    
    # Store first order ID for payment and success redirect
    render json: { 
      success: true, 
      order_id: orders_created.first.id,
      payment_url: pay_bus_ticket_order_path(orders_created.first),
      success_url: success_bus_ticket_order_path(orders_created.first)
    }
  end


  def pay
    @order = current_user.bus_ticket_orders.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Update order status to paid
    if @order.update(status: 'paid')
      # Update related orders (same user, same ticket, same create time) to paid
      BusTicketOrder.where(
        user: current_user,
        bus_ticket_id: @order.bus_ticket_id,
        created_at: @order.created_at
      ).update_all(status: 'paid')
      
      render json: { success: true }
    else
      render json: { success: false, message: '支付失败' }, status: :unprocessable_entity
    end
  end
  
  def success
    @order = current_user.bus_ticket_orders.find(params[:id])
    @bus_ticket = @order.bus_ticket
    # Get all orders from the same booking (same user, ticket, create time)
    @orders = BusTicketOrder.where(
      user: current_user,
      bus_ticket_id: @order.bus_ticket_id,
      created_at: @order.created_at
    ).order(:id)
  end

  def destroy
    # Write your real logic here
  end

  private
  # Write your private methods here
end
