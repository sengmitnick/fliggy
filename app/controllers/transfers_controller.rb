class TransfersController < ApplicationController
  include CitySelectorDataConcern
  before_action :authenticate_user!
  before_action :set_transfer, only: [:show, :pay, :cancel, :success]

  # GET /transfers - Homepage with service type selection (airport/train)
  def index
    @transfer_type = params[:transfer_type] || params[:type] || 'airport_pickup'
    @service_type = params[:service_type] || params[:service] || 'from_airport'
    
    # Get user's recent flight/train bookings for quick selection
    @recent_flights = current_user.bookings.where(status: ['confirmed', 'pending'])
                                  .includes(:offer)
                                  .order(departure_time: :desc)
                                  .limit(5) if @transfer_type == 'airport_pickup'
    
    @recent_trains = current_user.train_bookings.where(status: ['paid', 'locked'])
                                 .includes(:train)
                                 .order(created_at: :desc)
                                 .limit(5) if @transfer_type == 'train_pickup'
    
    # Session storage for multi-step form
    session[:transfer_params] ||= {}
    
    # Update session if flight_id or train_id is provided (coming back from search)
    if params[:flight_id].present?
      session[:transfer_params][:flight_id] = params[:flight_id]
      session[:transfer_params][:transfer_type] = @transfer_type
      session[:transfer_params][:service_type] = @service_type
    elsif params[:train_id].present?
      session[:transfer_params][:train_id] = params[:train_id]
      session[:transfer_params][:transfer_type] = @transfer_type
      session[:transfer_params][:service_type] = @service_type
    end
    
    @transfer_params = session[:transfer_params]
  end

  # GET /transfers/search_flights - Search flights by departure/arrival city
  def search_flights
    @departure_city = params[:departure_city]
    @arrival_city = params[:arrival_city]
    @departure_date = params[:departure_date]
    
    # Only search if at least departure and arrival cities are provided
    if @departure_city.present? && @arrival_city.present?
      @flights = Flight.all
      
      # Filter by date if provided (use flight_date column)
      if @departure_date.present?
        @flights = @flights.where('flight_date = ?', Date.parse(@departure_date))
      end
      
      # Filter by departure city AND arrival city (must match both)
      @flights = @flights.where(
        'departure_city LIKE ? AND destination_city LIKE ?',
        "%#{@departure_city}%",
        "%#{@arrival_city}%"
      )
      
      @flights = @flights.order(departure_time: :asc).limit(50)
      
      # Store search params in session
      session[:transfer_params] = (session[:transfer_params] || {}).merge(
        transfer_type: params[:transfer_type] || 'airport_pickup',
        service_type: params[:service_type] || 'from_airport',
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        departure_date: @departure_date
      )
    end
  end

  # GET /transfers/search_trains - Search train stations
  def search_trains
    @departure_station = params[:departure_station]
    @arrival_station = params[:arrival_station]
    @departure_date = params[:departure_date]
    
    return unless @departure_station.present? || @arrival_station.present?
    
    @trains = Train.all
    @trains = @trains.where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", Date.parse(@departure_date)) if @departure_date.present?
    @trains = @trains.where('departure_station LIKE ? OR arrival_station LIKE ?',
                           "%#{@departure_station}%", "%#{@arrival_station}%") if @departure_station || @arrival_station
    
    @trains = @trains.order(departure_time: :asc).limit(50)
    
    # Store search params in session
    session[:transfer_params] = (session[:transfer_params] || {}).merge(
      transfer_type: 'train_pickup',
      departure_station: @departure_station,
      arrival_station: @arrival_station,
      departure_date: @departure_date
    )
  end

  # GET /transfers/select_location - Select pickup/dropoff location
  def select_location
    @transfer_type = params[:transfer_type] || session.dig(:transfer_params, :transfer_type) || 'airport_pickup'
    @service_type = params[:service_type] || session.dig(:transfer_params, :service_type) || 'from_airport'
    @flight_id = params[:flight_id]
    @train_id = params[:train_id]
    
    # Get flight/train details if selected
    @flight = Flight.find_by(id: @flight_id) if @flight_id.present?
    @train = Train.find_by(id: @train_id) if @train_id.present?
    
    # Get user's saved addresses for quick selection
    @saved_addresses = current_user.addresses.order(created_at: :desc).limit(10)
    
    # Store params in session
    session[:transfer_params] = (session[:transfer_params] || {}).merge(
      transfer_type: @transfer_type,
      service_type: @service_type,
      flight_id: @flight_id,
      train_id: @train_id
    ).compact
  end

  # GET /transfers/packages - List available transfer packages
  def packages
    @flight_id = params[:flight_id] || session.dig(:transfer_params, :flight_id)
    @train_id = params[:train_id] || session.dig(:transfer_params, :train_id)
    @location_from = params[:location_from] || session.dig(:transfer_params, :location_from)
    @location_to = params[:location_to] || session.dig(:transfer_params, :location_to)
    @pickup_datetime = params[:pickup_datetime] || session.dig(:transfer_params, :pickup_datetime)
    @transfer_type = params[:transfer_type] || session.dig(:transfer_params, :transfer_type) || 'airport_pickup'
    @service_type = params[:service_type] || session.dig(:transfer_params, :service_type) || 'from_airport'
    
    # Redirect to search page if missing required params
    if @location_from.blank? || @location_to.blank?
      flash[:alert] = '请先选择出发地和目的地'
      redirect_to transfers_path and return
    end
    
    # Get flight/train details
    @flight = Flight.find_by(id: @flight_id) if @flight_id.present?
    @train = Train.find_by(id: @train_id) if @train_id.present?
    
    # Calculate pickup datetime from flight/train if not provided
    if @pickup_datetime.blank? && @flight.present?
      arrival_time = @flight.arrival_time
      @pickup_datetime = arrival_time + 30.minutes if arrival_time # 30 min buffer after landing
    elsif @pickup_datetime.blank? && @train.present?
      arrival_time = @train.arrival_time
      @pickup_datetime = arrival_time + 15.minutes if arrival_time # 15 min buffer after train arrives
    elsif @pickup_datetime.blank?
      # Default to 2 hours from now if no datetime provided
      @pickup_datetime = 2.hours.from_now
    end
    
    # Get available packages ordered by priority and price
    @packages = TransferPackage.active.ordered
    
    # Store params in session
    session[:transfer_params] = (session[:transfer_params] || {}).merge(
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime
    ).compact
  end

  # POST /transfers - Create new transfer order
  def create
    @transfer = current_user.transfers.build(transfer_params)
    @transfer.status = 'pending'
    @transfer.driver_status = 'pending'
    @transfer.discount_amount ||= 0
    
    # Get package details if package_id provided
    if params[:transfer][:transfer_package_id].present?
      package = TransferPackage.find(params[:transfer][:transfer_package_id])
      @transfer.transfer_package = package
      @transfer.total_price = package.price
      @transfer.provider_name = package.provider
      @transfer.vehicle_type = package.category_name
    end
    
    if @transfer.save
      # Clear session params
      session.delete(:transfer_params)
      
      # Redirect to show page
      redirect_to transfer_path(@transfer)
    else
      flash[:alert] = @transfer.errors.full_messages.join(', ')
      redirect_back fallback_location: transfers_path
    end
  end

  # PATCH /transfers/:id/pay - Process payment
  def pay
    # Process payment - check balance (password already verified by payment_confirmation_controller)
    required_amount = @transfer.actual_price
    if @transfer.pending? && current_user.balance >= required_amount
      # Deduct balance
      current_user.update!(balance: current_user.balance - required_amount)
      
      # Update transfer status
      @transfer.update!(status: 'paid', driver_status: 'accepted')
      
      # Create notification
      @transfer.create_transfer_notification
      
      render json: { success: true, message: '支付成功' }
    elsif !@transfer.pending?
      render json: { success: false, message: '订单状态异常' }, status: :unprocessable_entity
    else
      render json: { success: false, message: '余额不足，请先充值' }, status: :unprocessable_entity
    end
  end

  # GET /transfers/:id/success - Payment success page
  def success
    # This page shows after successful payment
  end

  # GET /transfers/:id - Order details
  def show
    # Show order details and driver status
  end

  # GET /transfers/my_orders - User's transfer orders list
  def my_orders
    @transfers = current_user.transfers
                             .includes(:transfer_package)
                             .order(created_at: :desc)
                             .page(params[:page]).per(20)
    
    # Filter by status if provided
    if params[:status].present? && ['pending', 'paid', 'completed', 'cancelled'].include?(params[:status])
      @transfers = @transfers.where(status: params[:status])
    end
  end

  # GET /transfers/locations - API endpoint to get transfer locations by city
  def locations
    city = params[:city]
    if city.blank?
      render json: { error: 'City parameter is required' }, status: :bad_request
      return
    end

    # Get locations from TransferLocation model (independent from Car rentals)
    locations = TransferLocation.locations_by_city(city)

    render json: {
      city: city,
      locations: locations
    }
  end

  # PATCH /transfers/:id/cancel - Cancel order
  def cancel
    if @transfer.pending? || @transfer.paid?
      @transfer.update!(status: 'cancelled', driver_status: 'cancelled')
      
      # Refund if already paid
      if @transfer.paid?
        current_user.add_balance(@transfer.actual_price)
        @transfer.update!(status: 'refunded')
      end
      
      redirect_to transfer_path(@transfer), notice: '订单已取消'
    else
      flash[:alert] = '该订单无法取消'
      redirect_to transfer_path(@transfer)
    end
  end

  private

  def set_transfer
    @transfer = current_user.transfers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transfers_path, alert: '订单不存在'
  end

  def transfer_params
    params.require(:transfer).permit(
      :transfer_type, :service_type, :location_from, :location_to,
      :pickup_datetime, :flight_number, :train_number,
      :passenger_name, :passenger_phone, :vehicle_type, :provider_name,
      :total_price, :discount_amount,
      :transfer_package_id
    )
  end
end
