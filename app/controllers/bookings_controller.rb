class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_flight, only: [:new, :create], unless: -> { params[:trip_type] == 'multi_city' }

  def index
    @status_filter = params[:status] || 'all'
    
    begin
      # Fetch flight bookings
      flight_bookings = current_user.bookings.includes(:flight, :return_flight)
                                    .order(created_at: :desc)
      
      # Fetch hotel bookings
      hotel_bookings = current_user.hotel_bookings.includes(:hotel, :hotel_room)
                                   .order(created_at: :desc)
      
      # Fetch tour group bookings
      tour_group_bookings = current_user.tour_group_bookings.includes(:tour_group_product, :tour_package)
                                        .order(created_at: :desc)
      
      # Fetch car orders
      car_orders = current_user.car_orders.includes(:car)
                               .order(created_at: :desc)
      
      # Fetch hotel package orders
      hotel_package_orders = current_user.hotel_package_orders.includes(:hotel_package, :package_option)
                                         .order(created_at: :desc)
      
      # Fetch bus ticket orders
      bus_ticket_orders = current_user.bus_ticket_orders.includes(:bus_ticket)
                                      .order(created_at: :desc)
      
      # Fetch visa orders
      visa_orders = current_user.visa_orders.includes(visa_product: :country)
                                .order(created_at: :desc)
      
      # Fetch abroad ticket orders
      abroad_ticket_orders = current_user.abroad_ticket_orders.includes(:abroad_ticket)
                                         .order(created_at: :desc)
      
      # Fetch internet orders
      internet_orders = current_user.internet_orders.includes(:orderable)
                                    .order(created_at: :desc)
      
      # Fetch transfer orders
      transfer_orders = current_user.transfers.includes(:transfer_package)
                                    .order(created_at: :desc)
      
      # Fetch custom travel requests
      custom_travel_requests = current_user.custom_travel_requests
                                           .order(created_at: :desc)
      
      # Fetch insurance orders
      insurance_orders = current_user.insurance_orders.includes(:insurance_product)
                                     .order(created_at: :desc)
    
    # Filter by status
    case @status_filter
    when 'pending'
      flight_bookings = flight_bookings.where(status: 'pending')
      hotel_bookings = hotel_bookings.where(status: 'pending')
      tour_group_bookings = tour_group_bookings.where(status: 'pending')
      car_orders = car_orders.where(status: 'pending')
      hotel_package_orders = hotel_package_orders.where(status: 'pending')
      bus_ticket_orders = bus_ticket_orders.where(status: 'pending')
      visa_orders = visa_orders.where(status: 'pending')
      abroad_ticket_orders = abroad_ticket_orders.where(status: 'pending')
      internet_orders = internet_orders.where(status: 'pending')
      transfer_orders = transfer_orders.where(status: 'pending')
      custom_travel_requests = custom_travel_requests.where(status: 'pending')
      insurance_orders = insurance_orders.where(status: 'pending')
    when 'upcoming'
      flight_bookings = flight_bookings.where(status: ['paid', 'completed'])
                                       .where('bookings.created_at >= ?', Date.today)
      hotel_bookings = hotel_bookings.where(status: ['paid', 'confirmed'])
                                     .where('hotel_bookings.check_in_date >= ?', Date.today)
      tour_group_bookings = tour_group_bookings.where(status: 'confirmed')
                                               .where('tour_group_bookings.travel_date >= ?', Date.today)
      car_orders = car_orders.where(status: 'paid')
                             .where('car_orders.pickup_datetime >= ?', DateTime.now)
      hotel_package_orders = hotel_package_orders.where(status: 'paid')
      bus_ticket_orders = bus_ticket_orders.where(status: 'paid')
                                           .joins(:bus_ticket)
                                           .where('bus_tickets.departure_date >= ?', Date.today)
      visa_orders = visa_orders.where(status: ['paid', 'processing'])
      abroad_ticket_orders = abroad_ticket_orders.where(status: 'paid')
                                                 .joins(:abroad_ticket)
                                                 .where('abroad_tickets.departure_date >= ?', Date.today)
      internet_orders = internet_orders.where(status: 'paid')
      transfer_orders = transfer_orders.where(status: 'paid')
                                       .where('transfers.pickup_datetime >= ?', DateTime.now)
      custom_travel_requests = custom_travel_requests.where(status: ['contacted', 'matched'])
      insurance_orders = insurance_orders.where(status: 'paid')
                                         .where('insurance_orders.start_date >= ?', Date.today)
    when 'review'
      # 待评价状态 - 已完成但未评价的订单（未实现评价系统，暂时为空）
      flight_bookings = flight_bookings.none
      hotel_bookings = hotel_bookings.none
      tour_group_bookings = tour_group_bookings.none
      car_orders = car_orders.none
      hotel_package_orders = hotel_package_orders.none
      bus_ticket_orders = bus_ticket_orders.none
      visa_orders = visa_orders.none
      abroad_ticket_orders = abroad_ticket_orders.none
      internet_orders = internet_orders.none
      transfer_orders = transfer_orders.none
      custom_travel_requests = custom_travel_requests.none
      insurance_orders = insurance_orders.none
    when 'refund'
      flight_bookings = flight_bookings.where(status: 'cancelled')
      hotel_bookings = hotel_bookings.where(status: 'cancelled')
      tour_group_bookings = tour_group_bookings.where(status: 'cancelled')
      car_orders = car_orders.where(status: 'cancelled')
      hotel_package_orders = hotel_package_orders.where(status: 'cancelled')
      bus_ticket_orders = bus_ticket_orders.where(status: 'cancelled')
      visa_orders = visa_orders.where(status: 'cancelled')
      abroad_ticket_orders = abroad_ticket_orders.where(status: 'cancelled')
      internet_orders = internet_orders.where(status: 'cancelled')
      transfer_orders = transfer_orders.where(status: 'cancelled')
      custom_travel_requests = custom_travel_requests.where(status: 'cancelled')
      insurance_orders = insurance_orders.where(status: 'cancelled')
    end
    
    # Combine and sort by created_at
    @all_bookings = [
      flight_bookings.to_a,
      hotel_bookings.to_a,
      tour_group_bookings.to_a,
      car_orders.to_a,
      hotel_package_orders.to_a,
      bus_ticket_orders.to_a,
      visa_orders.to_a,
      abroad_ticket_orders.to_a,
      internet_orders.to_a,
      transfer_orders.to_a,
      custom_travel_requests.to_a,
      insurance_orders.to_a
    ].flatten.compact.sort_by(&:created_at).reverse
    
    # Manual pagination
    @page = (params[:page] || 1).to_i
    @per_page = 10
    @total_count = @all_bookings.length
    @total_pages = (@total_count.to_f / @per_page).ceil
    @bookings = @all_bookings[(@page - 1) * @per_page, @per_page] || []
    
    rescue => e
      Rails.logger.error "Bookings index error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      @all_bookings = []
      @bookings = []
      @page = 1
      @per_page = 10
      @total_count = 0
      @total_pages = 0
      flash.now[:alert] = '加载订单列表时出现问题，请稍后重试'
    end
  end

  def new
    @booking = Booking.new
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    @trip_type = params[:trip_type] || 'one_way'
    
    # 多城市预订：从 selected_flights 参数中解析航班
    if @trip_type == 'multi_city'
      if params[:selected_flights].present?
        begin
          @selected_flights = JSON.parse(params[:selected_flights])
          # 加载所有选中的航班
          @multi_city_flights = @selected_flights.map do |selected|
            flight = Flight.find_by(id: selected['flight_id'])
            offer_id = selected['offer_id']
            offer = flight&.flight_offers&.find_by(id: offer_id) if offer_id.present?
            {
              flight: flight,
              offer: offer,
              segment_index: selected['segment_index']
            }
          end.compact
          
          if @multi_city_flights.empty?
            redirect_to flights_path, alert: '请选择航班'
            return
          end
        rescue JSON::ParserError
          redirect_to flights_path, alert: '航班数据格式错误'
          return
        end
      else
        redirect_to flights_path, alert: '请选择航班'
        return
      end
    else
      # 单程/往返预订
      @selected_offer = @flight.flight_offers.find_by(id: params[:offer_id]) if params[:offer_id]
      @return_flight = Flight.find_by(id: params[:return_flight_id]) if params[:return_flight_id]
      @return_offer = @return_flight.flight_offers.find_by(id: params[:return_offer_id]) if @return_flight && params[:return_offer_id]
    end
  end

  def create
    # DEBUG: Log current session variable state
    current_data_version = ActiveRecord::Base.connection.execute(
      "SELECT current_setting('app.data_version', true) AS version"
    ).first&.dig('version')
    Rails.logger.info "[BookingsController#create] Current app.data_version = #{current_data_version || 'NOT SET'}"
    
    @trip_type = params[:booking][:trip_type] || 'one_way'
    
    # Handle multi-city booking
    if @trip_type == 'multi_city'
      @booking = current_user.bookings.build(booking_params.except(:multi_city_flights_json))
      if params[:booking][:multi_city_flights_json].present?
        begin
          multi_city_data = JSON.parse(params[:booking][:multi_city_flights_json])
          @booking.trip_type = 'multi_city'
          @booking.multi_city_flights = multi_city_data
          
          # 使用第一个航班作为主航班
          first_flight_id = multi_city_data.first['flight_id']
          @booking.flight = Flight.find_by(id: first_flight_id)
          
          # 计算总价
          total_price = 0
          multi_city_data.each do |flight_data|
            flight = Flight.find_by(id: flight_data['flight_id'])
            if flight
              if flight_data['offer_id'].present?
                offer = flight.flight_offers.find_by(id: flight_data['offer_id'])
                total_price += offer&.price || flight.price
              else
                total_price += flight.price
              end
            end
          end
          @booking.total_price = total_price
          
          # 多程保险（按程数计算）
          if params[:booking][:insurance_price].present?
            insurance_price = params[:booking][:insurance_price].to_f
            @booking.insurance_price = insurance_price * multi_city_data.length
          end
        rescue JSON::ParserError => e
          flash.now[:alert] = '航班数据格式错误'
          @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
          render :new, status: :unprocessable_entity
          return
        end
      else
        flash.now[:alert] = '请选择航班'
        @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
        render :new, status: :unprocessable_entity
        return
      end
    elsif @trip_type == 'round_trip' && params[:booking][:return_flight_id].present?
      # Handle round-trip booking
      @booking = current_user.bookings.build(booking_params.except(:multi_city_flights_json))
      @booking.flight = @flight
      
      # 计算去程价格
      offer = @flight.flight_offers.find_by(id: params[:booking][:offer_id])
      @booking.total_price = offer&.price || @flight.price
      
      @booking.trip_type = 'round_trip'
      @booking.return_flight_id = params[:booking][:return_flight_id]
      @booking.return_date = Flight.find_by(id: params[:booking][:return_flight_id])&.flight_date
      
      # Add return flight price to total
      return_flight = Flight.find_by(id: params[:booking][:return_flight_id])
      if return_flight
        return_offer = return_flight.flight_offers.find_by(id: params[:booking][:return_offer_id])
        @booking.return_offer_id = return_offer&.id
        return_price = return_offer&.price || return_flight.price
        @booking.total_price += return_price
      end
      
      # 往返机票的保险费是双倍
      if params[:booking][:insurance_price].present?
        insurance_price = params[:booking][:insurance_price].to_f
        @booking.insurance_price = insurance_price * 2  # 往返双倍保险
      end
    else
      # Handle one-way booking
      @booking = current_user.bookings.build(booking_params.except(:multi_city_flights_json))
      @booking.flight = @flight
      
      # 计算去程价格
      offer = @flight.flight_offers.find_by(id: params[:booking][:offer_id])
      @booking.total_price = offer&.price || @flight.price
      
      # 单程保险
      @booking.insurance_price = params[:booking][:insurance_price].to_f if params[:booking][:insurance_price].present?
    end
    
    if @booking.save
      redirect_to booking_path(@booking), notice: '订单创建成功'
    else
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      
      if @trip_type == 'multi_city' && params[:booking][:multi_city_flights_json].present?
        # Reload multi-city flights for re-rendering
        begin
          multi_city_data = JSON.parse(params[:booking][:multi_city_flights_json])
          @multi_city_flights = multi_city_data.map do |flight_data|
            flight = Flight.find_by(id: flight_data['flight_id'])
            offer = flight&.flight_offers&.find_by(id: flight_data['offer_id']) if flight_data['offer_id'].present?
            {
              flight: flight,
              offer: offer,
              segment_index: flight_data['segment_index']
            }
          end.compact
        rescue JSON::ParserError
          # Handle error silently, form will show validation errors
        end
      else
        @selected_offer = @flight&.flight_offers&.find_by(id: params[:booking][:offer_id])
        @return_flight = Flight.find_by(id: params[:booking][:return_flight_id]) if params[:booking][:return_flight_id]
        @return_offer = @return_flight&.flight_offers&.find_by(id: params[:booking][:return_offer_id]) if @return_flight && params[:booking][:return_offer_id]
      end
      
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = current_user.bookings.find(params[:id])
    @flight = @booking.flight
  end

  def cancel
    @booking = current_user.bookings.find(params[:id])
    @booking.update!(status: :cancelled)
    redirect_to flights_path, notice: '订单已取消'
  end

  def pay
    @booking = current_user.bookings.find(params[:id])
    
    # Password already verified by frontend via /profile/verify_pay_password
    # Just process the payment
    @booking.update!(status: :paid)
    
    # 创建预订成功通知
    @booking.create_booking_notification
    
    # 创建出票成功通知
    @booking.create_ticket_issued_notification
    
    render json: { success: true }
  end

  def success
    @booking = current_user.bookings.find(params[:id])
    @flight = @booking.flight
  end

  private

  def set_flight
    if params[:flight_id].blank?
      redirect_to flights_path, alert: '请先选择航班'
      return
    end
    @flight = Flight.find(params[:flight_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to flights_path, alert: '航班不存在'
  end

  def booking_params
    params.require(:booking).permit(:passenger_name, :passenger_id_number, :contact_phone, :accept_terms, :insurance_type, :insurance_price, :trip_type, :return_flight_id, :return_date, :return_offer_id, :multi_city_flights_json)
  end
  
  # Helper methods for booking status display
  helper_method :booking_status_color, :booking_status_text
  
  def booking_status_color(status)
    case status
    when 'pending'
      'text-warning'
    when 'paid', 'processing'
      'text-success'
    when 'completed'
      'text-blue-600'
    when 'cancelled'
      'text-text-muted'
    else
      'text-text-primary'
    end
  end
  
  def booking_status_text(status)
    case status
    when 'pending'
      '待支付'
    when 'paid'
      '已支付'
    when 'processing'
      '办理中'
    when 'completed'
      '已完成'
    when 'cancelled'
      '已取消'
    else
      status
    end
  end
end
