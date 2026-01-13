class AbroadTicketOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :pay, :destroy]

  def new
    @ticket = AbroadTicket.find(params[:abroad_ticket_id])
    @passenger_type = params[:passenger_type] || '1adult'
    @seat_category = params[:seat_category] || '自由席'
    
    # Calculate price based on seat category
    @total_price = calculate_price(@ticket, @seat_category, @passenger_type)
    
    @order = AbroadTicketOrder.new(
      abroad_ticket: @ticket,
      passenger_type: @passenger_type,
      seat_category: @seat_category,
      total_price: @total_price
    )

    # Get user's passengers for quick selection
    @passengers = current_user.passengers.order(created_at: :desc).limit(5)
  end

  def create
    @ticket = AbroadTicket.find(params[:abroad_ticket_order][:abroad_ticket_id])
    @order = current_user.abroad_ticket_orders.build(order_params)
    @order.abroad_ticket = @ticket
    
    # Recalculate price to ensure accuracy
    @order.total_price = calculate_price(@ticket, @order.seat_category, @order.passenger_type)

    respond_to do |format|
      if @order.save
        format.html { redirect_to abroad_ticket_order_path(@order) }
        format.json { 
          render json: { 
            success: true, 
            order_id: @order.id,
            payment_url: pay_abroad_ticket_order_path(@order),
            success_url: success_abroad_ticket_order_path(@order)
          }, status: :created 
        }
      else
        format.html do
          @passengers = current_user.passengers.order(created_at: :desc).limit(5)
          render :new, status: :unprocessable_entity
        end
        format.json { 
          render json: { 
            success: false, 
            message: @order.errors.full_messages.join(', ') 
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  def show
    # Order details page before payment
  end

  def pay
    # Simulate payment processing
    respond_to do |format|
      if @order.update(status: 'paid')
        format.html { redirect_to success_abroad_ticket_order_path(@order) }
        format.json { render json: { success: true, message: '支付成功' }, status: :ok }
      else
        format.html { redirect_to abroad_ticket_order_path(@order), alert: '支付失败，请重试' }
        format.json { render json: { success: false, message: '支付失败，请重试' }, status: :unprocessable_entity }
      end
    end
  end

  def success
    @order = AbroadTicketOrder.find(params[:id])
  end

  def destroy
    @order.update(status: 'cancelled')
    redirect_to bookings_path, notice: '订单已取消'
  end

  private

  def set_order
    @order = current_user.abroad_ticket_orders.find(params[:id])
  end

  def order_params
    params.require(:abroad_ticket_order).permit(
      :abroad_ticket_id,
      :passenger_name,
      :passenger_id_number,
      :contact_phone,
      :contact_email,
      :passenger_type,
      :seat_category,
      :total_price,
      :notes
    )
  end

  def calculate_price(ticket, seat_category, passenger_type)
    base_price = ticket.price
    
    # Seat category multiplier
    multiplier = seat_category == '指定席' ? 1.06 : 1.0
    
    # Passenger type multiplier
    adult_count = passenger_type.match(/(\d+)adult/)[1].to_i rescue 1
    child_count = passenger_type.match(/(\d+)child/)[1].to_i rescue 0
    
    total = (base_price * multiplier * adult_count) + (base_price * multiplier * 0.5 * child_count)
    total.round(2)
  end
end
