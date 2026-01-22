class PassengersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_passenger, only: [:edit, :update, :destroy]
  before_action :set_traveler_type, only: [:index, :new, :edit]

  def index
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
  end

  def new
    @passenger = current_user.passengers.build
    @return_to = params[:return_to]
    @flight_id = params[:flight_id]
    @hotel_id = params[:hotel_id]
    @room_id = params[:room_id]
    @check_in = params[:check_in]
    @check_out = params[:check_out]
    @rooms = params[:rooms]
    @adults = params[:adults]
    @children = params[:children]
    @bus_ticket_id = params[:bus_ticket_id]
    @insurance_type = params[:insurance_type]
    # Deep travel booking params
    @guide_id = params[:guide_id]
    @date = params[:date]
    @adult_count = params[:adult_count]
    @child_count = params[:child_count]
  end

  def create
    @passenger = current_user.passengers.build(passenger_params)
    
    if @passenger.save
      if params[:return_to] == 'flights_index'
        redirect_to flights_path(open_passenger_modal: 'true'), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'booking_new'
        booking_params = {
          flight_id: params[:flight_id],
          offer_id: params[:offer_id],
          trip_type: params[:trip_type],
          return_flight_id: params[:return_flight_id],
          return_offer_id: params[:return_offer_id],
          selected_flights: params[:selected_flights]
        }.reject { |_k, v| v.blank? }
        redirect_to new_booking_path(booking_params), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'hotel_booking_new'
        redirect_to new_hotel_hotel_booking_path(
          params[:hotel_id],
          room_id: params[:room_id],
          check_in: params[:check_in],
          check_out: params[:check_out],
          rooms: params[:rooms],
          adults: params[:adults],
          children: params[:children]
        ), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'bus_ticket_order_new'
        redirect_to new_bus_ticket_order_path(
          bus_ticket_id: params[:bus_ticket_id],
          insurance_type: params[:insurance_type]
        ), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'deep_travel_booking_new'
        redirect_to new_deep_travel_booking_path(
          guide_id: params[:guide_id],
          date: params[:date],
          adult_count: params[:adult_count],
          child_count: params[:child_count]
        ), notice: "#{traveler_label}添加成功"
      else
        redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}添加成功"
      end
    else
      @traveler_type = params[:source]
      @return_to = params[:return_to]
      @flight_id = params[:flight_id]
      @offer_id = params[:offer_id]
      @trip_type = params[:trip_type]
      @return_flight_id = params[:return_flight_id]
      @return_offer_id = params[:return_offer_id]
      @selected_flights = params[:selected_flights]
      @hotel_id = params[:hotel_id]
      @room_id = params[:room_id]
      @check_in = params[:check_in]
      @check_out = params[:check_out]
      @rooms = params[:rooms]
      @adults = params[:adults]
      @children = params[:children]
      @bus_ticket_id = params[:bus_ticket_id]
      @insurance_type = params[:insurance_type]
      # Deep travel booking params
      @guide_id = params[:guide_id]
      @date = params[:date]
      @adult_count = params[:adult_count]
      @child_count = params[:child_count]
      render :new
    end
  end

  def edit
  end

  def update
    if @passenger.update(passenger_params)
      # Store return_to and reopen_modal in flash for showing return button
      if params[:return_to].present?
        flash[:return_to] = params[:return_to]
        flash[:reopen_modal] = params[:reopen_modal] if params[:reopen_modal].present?
        redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}更新成功"
      else
        redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}更新成功"
      end
    else
      @traveler_type = params[:source]
      render :edit
    end
  end

  def destroy
    @passenger.destroy
    redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}删除成功"
  end

  private

  def set_passenger
    @passenger = current_user.passengers.find(params[:id])
  end

  def set_traveler_type
    @traveler_type = params[:source]
  end

  def traveler_label
    case params[:source]
    when 'train'
      '乘车人'
    when 'bus'
      '乘车人'
    when 'flight'
      '乘机人'
    when 'hotel'
      '入住人'
    else
      '出行人'
    end
  end

  def passenger_params
    params.require(:passenger).permit(:name, :id_type, :id_number, :phone, :is_self)
  end

  def authenticate_user!
    unless current_user
      redirect_to sign_in_path, alert: '请先登录'
    end
  end
end
