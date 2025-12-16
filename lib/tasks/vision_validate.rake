# frozen_string_literal: true

# Vision Model Training - Task Validation CLI
# 
# 使用方法：
#   rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
#   rake vision:validate departure_city=北京 arrival_city=上海 departure_date=2025-01-20 passenger_name=张三 contact_phone=13800138000
#   rake vision:validate departure_city=广州 arrival_city=深圳 departure_date=2025-01-25 insurance_required=true
#   rake vision:validate departure_city=杭州 arrival_city=成都 departure_date=2025-01-30 should_complete_payment=false

namespace :vision do
  desc "验证机票预订任务完成情况"
  task validate: :environment do
    # 加载验证器
    require_relative '../../spec/validators/flight_booking_task_validator'
    
    # 解析命令行参数
    params = parse_validation_params
    
    # 显示任务信息
    print_task_info(params)
    
    # 创建验证器
    validator = FlightBookingTaskValidator.new(params)
    
    # 记录初始状态
    puts "\n📊 正在记录初始状态..."
    validator.record_initial_state
    puts "✅ 初始状态已记录"
    
    # 等待用户确认（模拟大模型执行）
    puts "\n⏸️  现在可以执行任务（手动操作或运行大模型）"
    puts "按 Enter 键继续验证..."
    STDIN.gets
    
    # 执行验证
    puts "\n🔍 正在验证任务结果..."
    result = validator.result
    
    # 显示验证结果
    print_validation_result(result, validator)
  end
  
  desc "显示验证工具使用说明"
  task help: :environment do
    puts <<~HELP
      
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      📋 Vision Model Training - 任务验证工具
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      
      ## 用途
      
      用于验证大模型（或手动操作）是否成功完成机票预订任务。
      
      ## 基本用法
      
      rake vision:validate [参数1=值1] [参数2=值2] ...
      
      ## 必填参数
      
      departure_city      出发城市（必填）
      arrival_city        到达城市（必填）
      departure_date      出发日期（必填，格式：YYYY-MM-DD）
      
      ## 可选参数
      
      user_id                    用户ID（默认：1）
      passenger_name             乘客姓名
      contact_phone              联系电话
      insurance_required         是否要求购买保险（true/false）
      insurance_forbidden        是否禁止购买保险（true/false）
      should_complete_payment    是否应完成支付（默认：true）
      
      ## 使用示例
      
      ### 示例 1：基础预订
      rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
      
      用户指令："帮我订1月15号从深圳到武汉的机票"
      
      ### 示例 2：指定乘客信息
      rake vision:validate departure_city=北京 arrival_city=上海 departure_date=2025-01-20 passenger_name=张三 contact_phone=13800138000
      
      用户指令："帮我订1月20号从北京到上海的机票，乘客姓名张三，手机号13800138000"
      
      ### 示例 3：要求购买保险
      rake vision:validate departure_city=广州 arrival_city=深圳 departure_date=2025-01-25 insurance_required=true
      
      用户指令："帮我订1月25号从广州到深圳的机票，要买保险"
      
      ### 示例 4：拒绝保险
      rake vision:validate departure_city=成都 arrival_city=重庆 departure_date=2025-01-28 insurance_forbidden=true
      
      用户指令："帮我订1月28号从成都到重庆的机票，不要买保险"
      
      ### 示例 5：只填表单，不支付
      rake vision:validate departure_city=杭州 arrival_city=成都 departure_date=2025-01-30 should_complete_payment=false
      
      用户指令："帮我填写1月30号从杭州到成都的机票预订表单，不用支付"
      
      ## 工作流程
      
      1. 运行命令并传入参数
      2. 工具记录当前数据库状态
      3. 提示用户执行任务（手动操作或运行大模型）
      4. 按 Enter 键开始验证
      5. 显示验证结果
      
      ## 验证规则
      
      ✅ 新预订创建：是否生成新的预订记录
      ✅ 航班路线：出发城市、到达城市是否匹配
      ✅ 出发日期：日期是否匹配（必填）
      ✅ 乘客信息：姓名、手机号是否匹配（如果指定）
      ✅ 保险选择：是否按要求购买/不购买保险
      ✅ 支付状态：是否完成支付
      
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      
    HELP
  end
  
  # 解析命令行参数
  def parse_validation_params
    params = {
      user_id: ENV["user_id"]&.to_i || 1,
      departure_city: ENV["departure_city"],
      arrival_city: ENV["arrival_city"],
      departure_date: ENV["departure_date"],
      should_complete_payment: parse_boolean(ENV["should_complete_payment"], true)
    }
    
    # 可选参数
    params[:passenger_name] = ENV["passenger_name"] if ENV["passenger_name"]
    params[:contact_phone] = ENV["contact_phone"] if ENV["contact_phone"]
    params[:insurance_required] = parse_boolean(ENV["insurance_required"]) if ENV["insurance_required"]
    params[:insurance_forbidden] = parse_boolean(ENV["insurance_forbidden"]) if ENV["insurance_forbidden"]
    
    # 验证必填参数
    missing_params = []
    missing_params << "departure_city" unless params[:departure_city]
    missing_params << "arrival_city" unless params[:arrival_city]
    missing_params << "departure_date" unless params[:departure_date]
    
    if missing_params.any?
      puts "\n❌ 缺少必填参数：#{missing_params.join(', ')}"
      puts "\n运行 'rake vision:help' 查看使用说明"
      exit 1
    end
    
    params
  end
  
  # 解析布尔值
  def parse_boolean(value, default = nil)
    return default if value.nil?
    value.to_s.downcase.in?([ "true", "1", "yes" ])
  end
  
  # 显示任务信息
  def print_task_info(params)
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "📋 机票预订任务验证"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 生成用户指令
    instruction = generate_user_instruction(params)
    puts "\n🗣️  用户指令："
    puts "   \"#{instruction}\""
    
    puts "\n📝 任务参数："
    puts "   用户ID: #{params[:user_id]}"
    puts "   出发城市: #{params[:departure_city]}"
    puts "   到达城市: #{params[:arrival_city]}"
    puts "   出发日期: #{params[:departure_date]}"
    puts "   乘客姓名: #{params[:passenger_name] || '（未指定）'}"
    puts "   联系电话: #{params[:contact_phone] || '（未指定）'}"
    
    if params[:insurance_required]
      puts "   保险要求: 必须购买"
    elsif params[:insurance_forbidden]
      puts "   保险要求: 不能购买"
    else
      puts "   保险要求: （未指定）"
    end
    
    puts "   是否支付: #{params[:should_complete_payment] ? '是' : '否'}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  end
  
  # 生成用户指令
  def generate_user_instruction(params)
    # 解析日期
    date = Date.parse(params[:departure_date])
    date_str = "#{date.month}月#{date.day}号"
    
    instruction = "帮我订#{date_str}从#{params[:departure_city]}到#{params[:arrival_city]}的机票"
    
    if params[:passenger_name] && params[:contact_phone]
      instruction += "，乘客姓名#{params[:passenger_name]}，手机号#{params[:contact_phone]}"
    elsif params[:passenger_name]
      instruction += "，乘客姓名#{params[:passenger_name]}"
    elsif params[:contact_phone]
      instruction += "，手机号#{params[:contact_phone]}"
    end
    
    if params[:insurance_required]
      instruction += "，要买保险"
    elsif params[:insurance_forbidden]
      instruction += "，不要买保险"
    end
    
    unless params[:should_complete_payment]
      instruction = "帮我填写#{date_str}从#{params[:departure_city]}到#{params[:arrival_city]}的机票预订表单，不用支付"
    end
    
    instruction
  end
  
  # 显示验证结果
  def print_validation_result(result, validator)
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if result[:valid]
      puts "✅ 验证通过！任务成功完成"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      
      # 显示新创建的预订详情
      if validator.instance_variable_get(:@new_booking)
        booking = validator.instance_variable_get(:@new_booking)
        puts "\n📦 预订详情："
        puts "   预订ID: #{booking.id}"
        puts "   航班号: #{booking.flight.flight_number}"
        puts "   路线: #{booking.flight.departure_city} → #{booking.flight.arrival_city}"
        puts "   日期: #{booking.flight.departure_time.strftime('%Y年%m月%d日')}"
        puts "   乘客: #{booking.passenger_name}"
        puts "   手机: #{booking.contact_phone}"
        puts "   保险: #{booking.insurance_type} #{booking.insurance_price > 0 ? "¥#{booking.insurance_price}" : ''}"
        puts "   状态: #{booking.status == 'paid' ? '已支付' : '待支付'}"
      end
    else
      puts "❌ 验证失败！任务未完成"
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      
      puts "\n🔍 错误详情："
      result[:errors].each_with_index do |error, index|
        puts "   #{index + 1}. #{error}"
      end
    end
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end
end
