class PassengersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_passenger, only: [:edit, :update, :destroy]
  before_action :set_traveler_type, only: [:index, :new, :edit]

  def index
    @passengers = current_user.passengers.order(created_at: :desc)
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
    
    Rails.logger.info "=== Passenger Create ==="
    Rails.logger.info "params[:return_to]: #{params[:return_to]}"
    Rails.logger.info "params[:source]: #{params[:source]}"
    
    if @passenger.save
      if params[:return_to] == 'flights_index'
        Rails.logger.info "Redirecting to flights_path with open_passenger_modal=true"
        redirect_to flights_path(open_passenger_modal: 'true'), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'booking_new'
        Rails.logger.info "Redirecting to new_booking_path with flight_id"
        redirect_to new_booking_path(flight_id: params[:flight_id]), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'hotel_booking_new'
        Rails.logger.info "Redirecting to new_hotel_hotel_booking_path with hotel_id and booking params"
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
        Rails.logger.info "Redirecting to new_bus_ticket_order_path with bus_ticket_id"
        redirect_to new_bus_ticket_order_path(
          bus_ticket_id: params[:bus_ticket_id],
          insurance_type: params[:insurance_type]
        ), notice: "#{traveler_label}添加成功"
      elsif params[:return_to] == 'deep_travel_booking_new'
        Rails.logger.info "Redirecting to new_deep_travel_booking_path with guide_id and params"
        redirect_to new_deep_travel_booking_path(
          guide_id: params[:guide_id],
          date: params[:date],
          adult_count: params[:adult_count],
          child_count: params[:child_count]
        ), notice: "#{traveler_label}添加成功"
      else
        Rails.logger.info "Redirecting to passengers_path"
        redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}添加成功"
      end
    else
      @traveler_type = params[:source]
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
      render :new
    end
  end

  def edit
  end

  def update
    if @passenger.update(passenger_params)
      redirect_to passengers_path(source: params[:source]), notice: "#{traveler_label}更新成功"
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
    params.require(:passenger).permit(:name, :id_type, :id_number, :phone)
  end

  def authenticate_user!
    unless current_user
      redirect_to sign_in_path, alert: '请先登录'
    end
  end
end
