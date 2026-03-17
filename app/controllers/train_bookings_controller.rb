class TrainBookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_train_booking, only: [:show, :lock, :success, :pay, :cancel]

  def new
    @train = Train.find(params[:train_id])
    @selected_seat_type = params[:seat_type] || 'second_class'
    @booking_option_id = params[:booking_option_id]
    
    # Initialize empty train_booking for form error display
    @train_booking = current_user.train_bookings.build(train: @train)
    
    # Load passengers for selection
    @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
    
    # Calculate base price based on seat type
    @base_price = case @selected_seat_type
    when 'second_class' then @train.price_second_class
    when 'first_class' then @train.price_first_class
    when 'business_class' then @train.price_business_class
    when 'no_seat' then @train.price_second_class * 0.5
    else @train.price_second_class
    end
    
    # Add extra fee from booking option if selected
    @booking_option_fee = 0
    @selected_price = @base_price
    if @booking_option_id.present?
      booking_option = @train.booking_options.find_by(id: @booking_option_id)
      if booking_option
        @booking_option_fee = booking_option.extra_fee
        @selected_price += @booking_option_fee
        @selected_booking_option = booking_option
      end
    end

    # Seat type label for display
    @seat_type_label = case @selected_seat_type
    when 'second_class' then '二等座'
    when 'first_class' then '一等座'
    when 'business_class' then '商务座'
    when 'no_seat' then '无座'
    when 'hard_sleeper' then '硬卧'
    when 'soft_sleeper' then '软卧'
    else '二等座'
    end

    @hot_cities = City.hot_cities.order(:pinyin)
    @all_cities = City.all.order(:pinyin)
  end

  def create
    @train = Train.find(params[:train_booking][:train_id])
    
    # Parse passenger IDs (like flight booking does)
    passenger_ids = if params[:train_booking][:passenger_ids].present?
      params[:train_booking][:passenger_ids].split(',').map(&:strip).reject(&:blank?)
    else
      # If no passenger IDs, use passenger_name to find single passenger
      passenger = current_user.passengers.find_by(name: params[:train_booking][:passenger_name])
      passenger ? [passenger.id.to_s] : []
    end
    
    if passenger_ids.empty?
      flash.now[:alert] = '请至少选择一位乘车人'
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      @train_booking = current_user.train_bookings.build
      load_train_data_for_render
      render :new, status: :unprocessable_entity
      return
    end
    
    passengers = current_user.passengers.where(id: passenger_ids)
    
    if passengers.empty?
      flash.now[:alert] = '未找到选中的乘车人'
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      @train_booking = current_user.train_bookings.build
      load_train_data_for_render
      render :new, status: :unprocessable_entity
      return
    end
    
    # Create separate booking for each passenger (like flight booking)
    booking_group_id = SecureRandom.uuid
    created_bookings = []
    errors_occurred = false
    
    passengers.each do |passenger|
      booking = create_booking_for_passenger(passenger, booking_group_id)
      if booking.persisted?
        created_bookings << booking
      else
        errors_occurred = true
        Rails.logger.error "Failed to create train booking for passenger #{passenger.name}: #{booking.errors.full_messages}"
      end
    end
    
    if errors_occurred
      # Rollback all created bookings on error
      created_bookings.each(&:destroy)
      
      # Initialize @train_booking for form error display
      first_passenger = passengers.first
      @train_booking = current_user.train_bookings.build(train_booking_params.except(:passenger_ids))
      @train_booking.passenger_name = first_passenger.name
      @train_booking.passenger_id_number = first_passenger.id_number
      @train_booking.valid?  # Trigger validation to populate errors
      
      flash.now[:alert] = '订单创建失败，请检查输入信息'
      @passengers = current_user.passengers.order(is_self: :desc, created_at: :desc)
      load_train_data_for_render
      render :new, status: :unprocessable_entity
    else
      # All bookings created successfully, redirect to first booking's lock page
      redirect_to lock_train_booking_path(created_bookings.first), notice: "订单创建成功（共#{created_bookings.size}个乘车人）"
    end
  end
  
  # Create booking for a single passenger (like flight booking)
  def create_booking_for_passenger(passenger, booking_group_id = nil)
    booking = current_user.train_bookings.build(train_booking_params.except(:passenger_ids))
    booking.booking_group_id = booking_group_id if booking_group_id.present?
    booking.passenger_name = passenger.name
    booking.passenger_id_number = passenger.id_number
    booking.passenger_phone = passenger.phone  # Store passenger's own phone number
    booking.train = @train
    
    # Calculate price for single passenger
    base_price = calculate_ticket_price(@train, booking.seat_type)
    # Child ticket is 50% of adult price
    booking.total_price = passenger.child_ticket? ? (base_price * 0.5) : base_price
    
    # Add booking option extra fee
    if booking.booking_option_id.present?
      booking_option = @train.booking_options.find_by(id: booking.booking_option_id)
      fee = booking_option&.extra_fee || 0
      booking.total_price += passenger.child_ticket? ? (fee * 0.5) : fee
    end
    
    # Add insurance fee per passenger
    if booking.insurance_price.present?
      booking.total_price += booking.insurance_price
    end
    
    booking.save
    booking
  end
  
  # Reload train data for re-rendering form on validation failure
  def load_train_data_for_render
    @selected_seat_type = params[:train_booking][:seat_type] || 'second_class'
    @booking_option_id = params[:train_booking][:booking_option_id]
    
    # Calculate base price
    @base_price = calculate_ticket_price(@train, @selected_seat_type)
    @booking_option_fee = 0
    @selected_price = @base_price
    if @booking_option_id.present?
      booking_option = @train.booking_options.find_by(id: @booking_option_id)
      if booking_option
        @booking_option_fee = booking_option.extra_fee
        @selected_price += @booking_option_fee
        @selected_booking_option = booking_option
      end
    end
    
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

    # 查询同一booking_group_id下的所有订单（多乘客场景）
    if @train_booking.booking_group_id.present?
      @all_bookings = current_user.train_bookings
        .where(booking_group_id: @train_booking.booking_group_id)
        .order(created_at: :asc)
      @total_group_price = @all_bookings.sum(:total_price)
      @passenger_count = @all_bookings.count
    else
      # 单乘客订单
      @all_bookings = [@train_booking]
      @total_group_price = @train_booking.total_price
      @passenger_count = 1
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
    
    # 查询同一booking_group_id下的所有订单（多乘客场景）
    if @train_booking.booking_group_id.present?
      @all_bookings = current_user.train_bookings
        .where(booking_group_id: @train_booking.booking_group_id)
        .order(created_at: :asc)
      @total_group_price = @all_bookings.sum(:total_price)
      @passenger_count = @all_bookings.count
    else
      # 单乘客订单
      @all_bookings = [@train_booking]
      @total_group_price = @train_booking.total_price
      @passenger_count = 1
    end
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
      :accept_terms,
      :passenger_ids  # Add passenger_ids parameter for multi-passenger booking
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
    when 'hard_sleeper'
      # 查找硬卧座位价格
      seat = train.train_seats.find_by(seat_type: 'hard_sleeper')
      seat&.price || train.price_second_class
    when 'soft_sleeper'
      # 查找软卧座位价格
      seat = train.train_seats.find_by(seat_type: 'soft_sleeper')
      seat&.price || train.price_first_class
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
    when 'hard_sleeper'
      # 硬卧：上中下铺 (如：001上、002中、003下)
      berth_number = rand(1..60)
      berth_position = ['上', '中', '下'].sample
      format('%03d%s', berth_number, berth_position)
    when 'soft_sleeper'
      # 软卧：上下铺 (如：001上、002下)
      berth_number = rand(1..40)
      berth_position = ['上', '下'].sample
      format('%03d%s', berth_number, berth_position)
    else
      '01A'
    end
  end
end
