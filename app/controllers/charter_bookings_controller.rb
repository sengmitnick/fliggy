class CharterBookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_charter_booking, only: [:show, :confirm, :pay, :success]

  def new
    # 订单填写页面
    @route = CharterRoute.friendly.find(params[:route_id])
    @vehicle_type = VehicleType.find(params[:vehicle_type_id])
    @departure_date = Date.parse(params[:departure_date])
    @duration_hours = params[:duration_hours].to_i
    @passengers_count = params[:passenger_count]&.to_i || 1
    
    # 计算价格
    @total_price = CharterPriceCalculatorService.call(
      route: @route,
      vehicle_type: @vehicle_type,
      duration_hours: @duration_hours,
      departure_date: @departure_date
    )
    
    # 初始化新订单对象（用于表单）
    @charter_booking = CharterBooking.new(
      charter_route: @route,
      vehicle_type: @vehicle_type,
      departure_date: @departure_date,
      departure_time: '09:00',
      duration_hours: @duration_hours,
      passengers_count: @passengers_count,
      booking_mode: 'by_route',
      total_price: @total_price,
      status: 'pending'
    )
    
    # 获取用户的常用联系人（如果有）
    @contacts = current_user.contacts.limit(3)
  end

  def create
    @charter_booking = current_user.charter_bookings.build(charter_booking_params)
    
    # 重新计算价格（防止前端篡改）
    @charter_booking.total_price = CharterPriceCalculatorService.call(
      route: @charter_booking.charter_route,
      vehicle_type: @charter_booking.vehicle_type,
      duration_hours: @charter_booking.duration_hours,
      departure_date: @charter_booking.departure_date
    )
    
    if @charter_booking.save
      redirect_to confirm_charter_booking_path(@charter_booking)
    else
      # Set all required instance variables for the form re-render
      @route = @charter_booking.charter_route
      @vehicle_type = @charter_booking.vehicle_type
      # Safely handle departure_date parsing
      @departure_date = if @charter_booking.departure_date.present?
                          @charter_booking.departure_date.is_a?(Date) ? @charter_booking.departure_date : Date.parse(@charter_booking.departure_date.to_s)
                        else
                          Time.zone.today + 1.day  # Fallback
                        end
      @duration_hours = @charter_booking.duration_hours || 8
      @passengers_count = @charter_booking.passengers_count || 1
      @total_price = @charter_booking.total_price || 0
      @contacts = current_user.contacts.limit(3)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # 订单详情页
  end

  def confirm
    # 订单确认页 - 显示订单详情，集成支付弹窗
    @route = @charter_booking.charter_route
    @vehicle_type = @charter_booking.vehicle_type
  end

  def pay
    # 处理支付（由payment_confirmation_controller触发）
    if @charter_booking.pay!
      render json: { success: true, redirect_url: success_charter_booking_path(@charter_booking) }
    else
      render json: { success: false, error: '支付失败，请重试' }, status: :unprocessable_entity
    end
  end

  def success
    # 支付成功页
    @route = @charter_booking.charter_route
  end

  private
  
  def set_charter_booking
    @charter_booking = current_user.charter_bookings.find(params[:id])
  end

  def charter_booking_params
    params.require(:charter_booking).permit(
      :charter_route_id,
      :vehicle_type_id,
      :departure_date,
      :departure_time,
      :duration_hours,
      :passengers_count,
      :booking_mode,
      :contact_name,
      :contact_phone,
      :note,
      :special_requirements
    )
  end
end
