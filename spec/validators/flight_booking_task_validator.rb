# frozen_string_literal: true

# 航班预订任务验证器
# 用于训练大模型的视觉理解和操作能力
# 验证大模型是否成功完成用户指定的预订任务

class FlightBookingTaskValidator
  attr_reader :errors, :task_params, :initial_booking_count

  def initialize(task_params)
    @task_params = task_params
    @errors = []
    @initial_booking_count = nil
  end

  # 记录任务开始前的状态
  def record_initial_state
    @initial_booking_count = Booking.where(user_id: task_params[:user_id]).count
  end

  # 验证任务是否成功完成
  def validate
    validate_new_booking_created
    validate_flight_route if errors.empty?
    validate_booking_details if errors.empty?
    validate_payment_status if errors.empty?
  end

  # 是否验证通过
  def valid?
    validate
    errors.empty?
  end

  # 获取验证结果
  def result
    {
      valid: valid?,
      errors: errors,
      task_params: task_params
    }
  end

  private

  # 验证是否创建了新的预订记录
  def validate_new_booking_created
    current_count = Booking.where(user_id: task_params[:user_id]).count
    
    if current_count <= initial_booking_count
      add_error("未创建新的预订记录")
    end
  end

  # 验证航班路线是否正确
  def validate_flight_route
    booking = find_latest_booking
    return unless booking

    flight = booking.flight
    unless flight
      add_error("预订没有关联的航班信息")
      return
    end

    # 验证出发城市
    expected_departure = task_params[:departure_city]
    unless flight.departure_city == expected_departure
      add_error("出发城市不匹配。期望：#{expected_departure}，实际：#{flight.departure_city}")
    end

    # 验证到达城市
    expected_arrival = task_params[:arrival_city]
    unless flight.destination_city == expected_arrival
      add_error("到达城市不匹配。期望：#{expected_arrival}，实际：#{flight.destination_city}")
    end

    # 验证出发日期（必填）
    unless task_params[:departure_date]
      add_error("任务未指定出发日期")
      return
    end

    expected_date = Date.parse(task_params[:departure_date].to_s)
    actual_date = flight.departure_time.to_date
    unless actual_date == expected_date
      add_error("出发日期不匹配。期望：#{expected_date}，实际：#{actual_date}")
    end
  end

  # 验证预订详情
  def validate_booking_details
    booking = find_latest_booking
    return unless booking

    # 验证乘客姓名（如果指定）
    if task_params[:passenger_name]
      unless booking.passenger_name == task_params[:passenger_name]
        add_error("乘客姓名不匹配。期望：#{task_params[:passenger_name]}，实际：#{booking.passenger_name}")
      end
    end

    # 验证联系电话（如果指定）
    if task_params[:contact_phone]
      unless booking.contact_phone == task_params[:contact_phone]
        add_error("联系电话不匹配。期望：#{task_params[:contact_phone]}，实际：#{booking.contact_phone}")
      end
    end

    # 验证保险选择（如果指定）
    if task_params[:insurance_required] == true
      if booking.insurance_type == "无保障"
        add_error("需要购买保险，但实际选择了无保障")
      end
    elsif task_params[:insurance_required] == false
      unless booking.insurance_type == "无保障"
        add_error("不需要购买保险，但实际购买了保险")
      end
    end
  end

  # 验证支付状态
  def validate_payment_status
    booking = find_latest_booking
    return unless booking

    # 检查是否需要完成支付
    if task_params[:should_complete_payment] == true
      unless booking.paid?
        add_error("任务要求完成支付，但预订状态为：#{booking.status}")
      end
    end
  end

  # 查找最新的预订记录
  def find_latest_booking
    @latest_booking ||= Booking.where(user_id: task_params[:user_id])
                               .order(created_at: :desc)
                               .first
  end

  # 添加错误信息
  def add_error(message)
    @errors << message
  end
end
