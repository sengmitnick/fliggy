# frozen_string_literal: true

# API: 验证任务控制器
#
# 用于远程调用的验证任务 API
# 适合大模型训练场景：先创建任务 → 执行操作 → 验证结果
#
# 使用示例：
#   # 1. 创建验证任务
#   POST /api/validation_tasks
#   {
#     "departure_city": "深圳",
#     "arrival_city": "武汉",
#     "departure_date": "2025-01-15"
#   }
#
#   # 2. 大模型执行任务...
#
#   # 3. 验证结果
#   POST /api/validation_tasks/:task_id/verify

class Api::ValidationTasksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # POST /api/validation_tasks
  # 创建验证任务并记录初始状态
  def create
    # 解析参数
    task_params = parse_task_params
    
    # 验证必填参数
    missing_params = validate_required_params(task_params)
    if missing_params.any?
      return render json: {
        success: false,
        error: "缺少必填参数：#{missing_params.join(', ')}",
        missing_params: missing_params
      }, status: :bad_request
    end
    
    # 创建验证器
    validator = create_validator(task_params)
    
    # 记录初始状态
    validator.record_initial_state
    
    # 保存任务信息到 session 或缓存
    task_id = SecureRandom.uuid
    Rails.cache.write("validation_task:#{task_id}", {
      params: task_params,
      initial_booking_count: validator.instance_variable_get(:@initial_booking_count),
      created_at: Time.current
    }, expires_in: 1.hour)
    
    # 生成用户指令
    user_instruction = generate_user_instruction(task_params)
    
    render json: {
      success: true,
      task_id: task_id,
      message: "验证任务已创建，初始状态已记录",
      task_info: {
        user_instruction: user_instruction,
        params: task_params,
        initial_booking_count: validator.instance_variable_get(:@initial_booking_count)
      },
      next_step: "执行预订任务后，调用 POST /api/validation_tasks/#{task_id}/verify 进行验证"
    }, status: :created
  end
  
  # POST /api/validation_tasks/:task_id/verify
  # 验证任务结果
  def verify
    task_id = params[:id]
    
    # 获取任务信息
    task_data = Rails.cache.read("validation_task:#{task_id}")
    unless task_data
      return render json: {
        success: false,
        error: "任务不存在或已过期",
        task_id: task_id
      }, status: :not_found
    end
    
    # 创建验证器
    validator = create_validator(task_data[:params])
    
    # 恢复初始状态
    validator.instance_variable_set(:@initial_booking_count, task_data[:initial_booking_count])
    validator.instance_variable_set(:@initial_recorded, true)
    
    # 执行验证
    result = validator.result
    
    # 获取预订详情（如果验证成功）
    booking_details = nil
    if result[:valid]
      booking = validator.instance_variable_get(:@new_booking)
      if booking
        booking_details = format_booking_details(booking)
      end
    end
    
    # 清除任务缓存
    Rails.cache.delete("validation_task:#{task_id}")
    
    render json: {
      success: result[:valid],
      task_id: task_id,
      validation_result: {
        valid: result[:valid],
        errors: result[:errors],
        booking_details: booking_details
      },
      message: result[:valid] ? "验证通过！任务成功完成" : "验证失败！任务未完成"
    }, status: result[:valid] ? :ok : :unprocessable_entity
  end
  
  # GET /api/validation_tasks/:task_id
  # 获取任务状态
  def show
    task_id = params[:id]
    
    task_data = Rails.cache.read("validation_task:#{task_id}")
    unless task_data
      return render json: {
        success: false,
        error: "任务不存在或已过期",
        task_id: task_id
      }, status: :not_found
    end
    
    user_instruction = generate_user_instruction(task_data[:params])
    
    render json: {
      success: true,
      task_id: task_id,
      task_info: {
        user_instruction: user_instruction,
        params: task_data[:params],
        initial_booking_count: task_data[:initial_booking_count],
        created_at: task_data[:created_at],
        expires_at: task_data[:created_at] + 1.hour
      },
      status: "waiting_for_execution",
      message: "任务等待执行中"
    }
  end
  
  # DELETE /api/validation_tasks/:task_id
  # 取消任务
  def destroy
    task_id = params[:id]
    
    if Rails.cache.delete("validation_task:#{task_id}")
      render json: {
        success: true,
        task_id: task_id,
        message: "任务已取消"
      }
    else
      render json: {
        success: false,
        error: "任务不存在或已过期",
        task_id: task_id
      }, status: :not_found
    end
  end
  
  private
  
  def parse_task_params
    {
      user_id: params[:user_id] || 1,
      departure_city: params[:departure_city],
      arrival_city: params[:arrival_city],
      departure_date: params[:departure_date],
      passenger_name: params[:passenger_name],
      contact_phone: params[:contact_phone],
      insurance_required: parse_boolean(params[:insurance_required]),
      insurance_forbidden: parse_boolean(params[:insurance_forbidden]),
      should_complete_payment: parse_boolean(params[:should_complete_payment], true)
    }.compact
  end
  
  def parse_boolean(value, default = nil)
    return default if value.nil?
    [ "true", "1", "yes", true ].include?(value)
  end
  
  def validate_required_params(task_params)
    required = [ :departure_city, :arrival_city, :departure_date ]
    required.select { |param| task_params[param].blank? }.map(&:to_s)
  end
  
  def create_validator(task_params)
    require_relative '../../../spec/validators/flight_booking_task_validator'
    FlightBookingTaskValidator.new(task_params)
  end
  
  def generate_user_instruction(task_params)
    date = Date.parse(task_params[:departure_date].to_s)
    date_str = "#{date.month}月#{date.day}号"
    
    instruction = "帮我订#{date_str}从#{task_params[:departure_city]}到#{task_params[:arrival_city]}的机票"
    
    if task_params[:passenger_name] && task_params[:contact_phone]
      instruction += "，乘客姓名#{task_params[:passenger_name]}，手机号#{task_params[:contact_phone]}"
    elsif task_params[:passenger_name]
      instruction += "，乘客姓名#{task_params[:passenger_name]}"
    elsif task_params[:contact_phone]
      instruction += "，手机号#{task_params[:contact_phone]}"
    end
    
    if task_params[:insurance_required]
      instruction += "，要买保险"
    elsif task_params[:insurance_forbidden]
      instruction += "，不要买保险"
    end
    
    unless task_params[:should_complete_payment]
      instruction = "帮我填写#{date_str}从#{task_params[:departure_city]}到#{task_params[:arrival_city]}的机票预订表单，不用支付"
    end
    
    instruction
  end
  
  def format_booking_details(booking)
    {
      booking_id: booking.id,
      flight: {
        flight_number: booking.flight.flight_number,
        departure_city: booking.flight.departure_city,
        destination_city: booking.flight.destination_city,
        departure_time: booking.flight.departure_time,
        arrival_time: booking.flight.arrival_time,
        departure_date: booking.flight.departure_time.to_date
      },
      passenger: {
        name: booking.passenger_name,
        phone: booking.contact_phone
      },
      insurance: {
        type: booking.insurance_type,
        price: booking.insurance_price
      },
      status: booking.status,
      total_price: booking.total_price,
      created_at: booking.created_at
    }
  end
end
