class TrainBookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_train_booking, only: [:show, :lock, :success, :pay, :cancel]

  def new
    @train = Train.find(params[:train_id])
    @selected_seat_type = params[:seat_type] || 'second_class'
    @booking_option_id = params[:booking_option_id]
    
    # Calculate base price based on seat type
    base_price = case @selected_seat_type
    when 'second_class' then @train.price_second_class
    when 'first_class' then @train.price_first_class
    when 'business_class' then @train.price_business_class
    when 'no_seat' then @train.price_second_class * 0.5
    else @train.price_second_class
    end
    
    # Add extra fee from booking option if selected
    @selected_price = base_price
    if @booking_option_id.present?
      booking_option = @train.booking_options.find_by(id: @booking_option_id)
      @selected_price += booking_option.extra_fee if booking_option
      @selected_booking_option = booking_option
    end

    # Seat type label for display
    @seat_type_label = case @selected_seat_type
    when 'second_class' then '二等座'
    when 'first_class' then '一等座'
    when 'business_class' then '商务座'
    when 'no_seat' then '无座'
    else '二等座'
    end

    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
  end

  def create
    @train = Train.find(params[:train_booking][:train_id])
    @train_booking = current_user.train_bookings.build(train_booking_params)
    @train_booking.train = @train

    # 计算总价（基础票价 + 预订选项额外费用 + 保险价格）
    base_price = calculate_ticket_price(@train, @train_booking.seat_type)
    @train_booking.total_price = base_price
    
    # 添加预订选项额外费用
    if @train_booking.booking_option_id.present?
      booking_option = @train.booking_options.find_by(id: @train_booking.booking_option_id)
      @train_booking.total_price += booking_option.extra_fee if booking_option
    end
    
    # 添加保险费用
    if @train_booking.insurance_price.present?
      @train_booking.total_price += @train_booking.insurance_price
    end

    if @train_booking.save
      # 创建订单成功后，跳转到锁定页面
      redirect_to lock_train_booking_path(@train_booking)
    else
      # 验证失败，返回预订页
      @selected_seat_type = @train_booking.seat_type
      @booking_option_id = @train_booking.booking_option_id
      
      # 重新计算价格
      base_price = calculate_ticket_price(@train, @selected_seat_type)
      @selected_price = base_price
      if @booking_option_id.present?
        booking_option = @train.booking_options.find_by(id: @booking_option_id)
        @selected_price += booking_option.extra_fee if booking_option
        @selected_booking_option = booking_option
      end
      
      @seat_type_label = @train_booking.seat_type_label
      @hot_cities = City.hot_cities.order(:pinyin)
      @all_cities = City.all.order(:pinyin)
      render 'train_bookings/new', status: :unprocessable_entity
    end
  end

  def show
    @train = @train_booking.train
  end

  def lock
    # 座位锁定页面 - 显示锁定进度
    @train = @train_booking.train
    
    # 如果订单状态已经是paid或completed，直接跳转到支付成功页
    if @train_booking.paid? || @train_booking.completed?
      redirect_to success_train_booking_path(@train_booking)
      return
    end

    # 模拟座位锁定过程，随机生成座位号（如果用户选择了在线选座）
    if @train_booking.carriage_number.present? && @train_booking.seat_number.blank?
      @train_booking.update(seat_number: generate_seat_number(@train_booking.seat_type))
    elsif @train_booking.seat_number.blank?
      # 用户选择了随机分配座位
      @train_booking.update(
        carriage_number: generate_carriage_number,
        seat_number: generate_seat_number(@train_booking.seat_type)
      )
    end
  end

  def pay
    # 处理支付请求
    # 密码验证已在前端通过 /profile/verify_pay_password 完成
    # 这里直接处理支付
    @train_booking.update!(status: :paid)
    
    # 创建预订成功通知
    @train_booking.create_booking_notification
    
    # 创建出票成功通知
    @train_booking.create_ticket_issued_notification
    
    render json: { success: true }
  end

  def success
    # 支付成功页面
    @train = @train_booking.train
  end

  def cancel
    # 取消订单
    @train_booking.update!(status: :cancelled)
    redirect_to trains_path, notice: '订单已取消'
  end

  private

  def set_train_booking
    @train_booking = current_user.train_bookings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to trains_path, alert: '订单不存在'
  end

  def train_booking_params
    params.require(:train_booking).permit(
      :train_id,
      :passenger_name,
      :passenger_id_number,
      :contact_phone,
      :seat_type,
      :booking_option_id,
      :carriage_number,
      :seat_number,
      :insurance_type,
      :insurance_price,
      :accept_terms
    )
  end

  def calculate_ticket_price(train, seat_type)
    # 根据座位类型计算票价
    case seat_type
    when 'second_class'
      train.price_second_class
    when 'first_class'
      train.price_first_class
    when 'business_class'
      train.price_business_class
    when 'no_seat'
      train.price_second_class * 0.5
    else
      train.price_second_class
    end
  end

  def generate_carriage_number
    # 生成随机车厢号（03-08）
    format('%02d', rand(3..8))
  end

  def generate_seat_number(seat_type)
    # 根据座位类型生成座位号
    case seat_type
    when 'second_class'
      # 二等座：01A-18F (每排5个座位，共18排)
      row = rand(1..18)
      seat = ['A', 'B', 'C', 'D', 'F'].sample
      format('%02d%s', row, seat)
    when 'first_class'
      # 一等座：01A-10D (每排4个座位，共10排)
      row = rand(1..10)
      seat = ['A', 'B', 'C', 'D'].sample
      format('%02d%s', row, seat)
    when 'business_class'
      # 商务座：01A-05C (每排3个座位，共5排)
      row = rand(1..5)
      seat = ['A', 'B', 'C'].sample
      format('%02d%s', row, seat)
    when 'no_seat'
      # 无座：不分配座位号
      '无座'
    else
      '01A'
    end
  end
end
