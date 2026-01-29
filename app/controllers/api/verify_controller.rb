# frozen_string_literal: true

module Api
  # API 控制器：验证任务管理
  # 
  # 提供接口：
  # - GET /api/tasks - 列出所有可用验证器
  # - POST /api/tasks/:id/start - 创建训练会话
  # - POST /api/verify/run - 验证接口
  # 
  # 向下兼容接口：
  # - GET /api/verify - 列出所有可用验证器（兼容）
  # - POST /api/verify/:id/prepare - 准备验证环境（兼容）
  # - POST /api/verify/:execution_id/result - 验证结果（兼容）
  class VerifyController < BaseController
    # 互斥锁确保同一时间只有一个验证在执行
    VERIFY_LOCK = Mutex.new
    
    # GET /api/tasks
    # GET /api/verify (向下兼容)
    # 获取所有可用的验证器列表
    def index
      validators = load_all_validators.map(&:metadata)
      
      render json: { 
        validators: validators,
        count: validators.size
      }
    end
    
    # POST /api/verify/:id/prepare
    # 准备验证环境（在事务中加载数据）
    def prepare
      VERIFY_LOCK.synchronize do
        validator_class = find_validator(params[:id])
        execution_id = SecureRandom.uuid
        
        instance = validator_class.new(execution_id)
        prepare_info = instance.execute_prepare
        
        # 获取当前用户（支持认证用户和默认用户）
        user = current_user || get_default_user
        
        # 查找刚刚创建的 ValidatorExecution 记录（在 execute_prepare 中创建）
        execution = ValidatorExecution.find_by(execution_id: execution_id)
        
        if execution && user
          # 设置为活跃会话（同时取消同一用户的其他活跃会话）
          execution.update!(user_id: user.id)
          execution.activate!
          
          Rails.logger.info "[Validator] Started validation session #{execution_id} for user #{user.id}"
        end
        
        render json: {
          execution_id: execution_id,
          validator_id: validator_class.validator_id,
          prepare_info: prepare_info,
          timeout_seconds: validator_class.timeout_seconds,
          message: "环境已准备完成，请开始操作。完成后调用 POST /api/verify/#{execution_id}/result 进行验证"
        }
      end
    rescue StandardError => e
      render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :unprocessable_entity
    end
    
    # POST /api/verify/:execution_id/result
    # 验证执行结果
    def result
      VERIFY_LOCK.synchronize do
        execution_id = params[:execution_id]
        
        # 从数据库获取 validator 类型
        execution = ValidatorExecution.find_by(execution_id: execution_id)
        
        unless execution
          return render json: { error: "验证会话不存在或已过期: #{execution_id}" }, status: :not_found
        end
        
        state_data = execution.state_data
        validator_class = state_data['validator_class'].constantize
        
        instance = validator_class.new(execution_id)
        verify_result = instance.execute_verify
        
        # 验证完成后取消活跃状态
        execution.deactivate!
        
        render json: verify_result
      end
    rescue StandardError => e
      render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :unprocessable_entity
    end
    
    # POST /api/tasks/:id/start
    # 甲方规范：创建训练会话
    # 返回：{ task: {...}, session_id: "xxx" }
    def start_task
      VERIFY_LOCK.synchronize do
        task_id = params[:id]
        
        # 复用 prepare 逻辑
        validator_class = find_validator(task_id)
        session_id = SecureRandom.uuid  # 等同于 execution_id
        
        instance = validator_class.new(session_id)
        prepare_info = instance.execute_prepare
        
        # 获取当前用户（支持认证用户和默认用户）
        user = current_user || get_default_user
        
        # 查找刚刚创建的 ValidatorExecution 记录（在 execute_prepare 中创建）
        execution = ValidatorExecution.find_by(execution_id: session_id)
        
        if execution && user
          # 设置为活跃会话（同时取消同一用户的其他活跃会话）
          execution.update!(user_id: user.id)
          execution.activate!
          
          Rails.logger.info "[Validator] Started validation session #{session_id} for user #{user.id}"
        end
        
        # 按照甲方格式返回
        render json: {
          task: prepare_info,            # 任务信息（instruction 等）
          session_id: session_id,        # 会话 ID
          task_id: task_id               # 任务 ID（回显）
        }
      end
    rescue StandardError => e
      render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :unprocessable_entity
    end
    
    # POST /api/verify/run
    # 甲方规范：验证接口
    # 参数：{ task_id: "xxx", session_id: "xxx" }
    # 返回：{ score: 0.59, reason: "xxx", execution_status: "success", metadata: {...} }
    def run_verification
      VERIFY_LOCK.synchronize do
        task_id = params[:task_id]
        session_id = params[:session_id]
        
        unless session_id
          return render json: {
            score: 0.0,
            reason: "缺少 session_id 参数",
            execution_status: "fail"
          }, status: :bad_request
        end
        
        # 复用 result 逻辑
        execution = ValidatorExecution.find_by(execution_id: session_id)
        
        unless execution
          return render json: {
            score: 0.0,
            reason: "验证会话不存在或已过期: #{session_id}",
            execution_status: "fail"
          }, status: :not_found
        end
        
        begin
          state_data = execution.state_data
          validator_class = state_data['validator_class'].constantize
          
          instance = validator_class.new(session_id)
          verify_result = instance.execute_verify
          
          # 验证完成后取消活跃状态
          execution.deactivate!
          
          # 转换为甲方格式
          render json: transform_to_client_format(verify_result)
          
        rescue StandardError => e
          # 系统级错误（非 Agent 做错）
          render json: {
            score: 0.0,
            reason: "系统内部错误: #{e.message}",
            execution_status: "fail",  # 系统级失败
            metadata: {
              error_type: e.class.name,
              backtrace: e.backtrace.first(3)
            }
          }, status: :internal_server_error
        end
      end
    end
    
    private
    
    # 加载所有验证器类
    def load_all_validators
      # 自动加载 app/validators/*_validator.rb
      validator_files = Dir[Rails.root.join('app/validators/*_validator.rb')]
      
      validator_files.map do |file|
        # 跳过 base_validator.rb
        next if file.end_with?('base_validator.rb')
        
        class_name = File.basename(file, '.rb').camelize
        class_name.constantize
      end.compact.select { |klass| klass < BaseValidator }
    end
    
    # 根据 ID 查找验证器（支持 validator_id 或 task_id）
    def find_validator(id)
      validator = load_all_validators.find { |v| v.validator_id == id || v.task_id == id }
      raise "验证器不存在: '#{id}'" unless validator
      
      validator
    end
    
    # 获取默认用户（用于未认证的 API 请求）
    def get_default_user
      User.find_by(email: 'demo@travel01.com')
    end
    
    # 转换返回格式为甲方规范
    # verify_result 结构:
    # {
    #   execution_id: "xxx",
    #   status: "passed"/"failed"/"error",
    #   score: 100,  # 0-100 整数
    #   assertions: [{ name: "xxx", weight: 20, passed: true, error: nil }, ...],
    #   errors: ["订单已创建: 未找到订单", ...]
    # }
    def transform_to_client_format(verify_result)
      # 转换 score: 100 -> 1.0 (0-100 -> 0-1)
      normalized_score = verify_result[:score] / 100.0
      
      # 判断 execution_status
      # 系统级错误（非 Agent 做错）的特征：
      # 1. verify_result[:status] == 'error' (后端异常)
      # 2. errors 中包含前端系统错误特征（如 "Missing target", "undefined is not a function", "Cannot read property" 等）
      execution_status = if verify_result[:status] == 'error'
                           'fail'  # 后端系统级错误
                         elsif contains_frontend_system_error?(verify_result[:errors])
                           'fail'  # 前端系统级错误
                         else
                           'success'  # 验证逻辑正常执行（Agent 可能做错，但系统正常）
                         end
      
      # 转换 reason（失败原因）
      reason = if verify_result[:errors].empty?
                 "验证通过"
               else
                 verify_result[:errors].join("; ")
               end
      
      # 转换 metadata.details（子步骤详情）
      details = verify_result[:assertions].map.with_index do |assertion, index|
        # 使用下划线连接中文名称，保留原文
        child_verify_id = "step_#{index + 1}_#{assertion[:name].gsub(/\s+/, '_')}"
        
        {
          child_verify_id: child_verify_id,
          score: assertion[:passed] ? 1.0 : 0.0,  # 子步骤得分（0 或 1）
          weight: assertion[:weight] / 100.0,     # 权重归一化（20 -> 0.2）
          child_reason: {
            passed: assertion[:passed],
            error: assertion[:error]
          }
        }
      end
      
      {
        score: normalized_score,
        reason: reason,
        execution_status: execution_status,
        metadata: {
          details: {
            process: [],  # 预留字段（可用于记录操作步骤）
            result: details
          }
        }
      }
    end
    
    # 检测错误信息中是否包含前端系统错误特征
    # 这些错误表明前端代码/环境出问题，而非 Agent 操作错误
    def contains_frontend_system_error?(errors)
      return false if errors.nil? || errors.empty?
      
      # 前端系统错误的关键词特征
      frontend_error_patterns = [
        /Missing target element/i,              # Stimulus target 缺失
        /is not defined/i,                     # JS 变量未定义
        /undefined is not a function/i,        # 调用未定义的函数
        /Cannot read property.*of undefined/i, # 访问 undefined 的属性
        /Cannot read property.*of null/i,      # 访问 null 的属性
        /SyntaxError:/i,                       # JS 语法错误
        /ReferenceError:/i,                    # JS 引用错误
        /TypeError:.*is not a function/i,      # 类型错误
        /Controller.*is not registered/i,      # Stimulus controller 未注册
        /Action.*not found/i,                  # Stimulus action 不存在
        /Failed to fetch/i,                    # 网络请求失败（可能是系统问题）
        /NetworkError/i,                       # 网络错误
        /CORS.*blocked/i                       # CORS 跨域错误
      ]
      
      # 检查每个 error 是否匹配前端错误特征
      errors.any? do |error_msg|
        frontend_error_patterns.any? { |pattern| error_msg.to_s.match?(pattern) }
      end
    end
  end
end
