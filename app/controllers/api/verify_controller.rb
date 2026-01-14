# frozen_string_literal: true

module Api
  # API 控制器：验证任务管理
  # 
  # 提供接口：
  # - GET /api/verify - 列出所有可用验证器
  # - POST /api/verify/:id/prepare - 准备验证环境
  # - POST /api/verify/:execution_id/result - 验证结果
  class VerifyController < BaseController
    # 互斥锁确保同一时间只有一个验证在执行
    VERIFY_LOCK = Mutex.new
    
    # GET /api/verify
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
        result_row = ActiveRecord::Base.connection.execute(
          "SELECT state FROM validator_executions WHERE execution_id = #{ActiveRecord::Base.connection.quote(execution_id)}"
        ).first
        
        unless result_row
          return render json: { error: "验证会话不存在或已过期: #{execution_id}" }, status: :not_found
        end
        
        state = JSON.parse(result_row['state'])
        validator_class = state['validator_class'].constantize
        
        instance = validator_class.new(execution_id)
        verify_result = instance.execute_verify
        
        render json: verify_result
      end
    rescue StandardError => e
      render json: { error: e.message, backtrace: e.backtrace.first(3) }, status: :unprocessable_entity
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
    
    # 根据 ID 查找验证器
    def find_validator(id)
      validator = load_all_validators.find { |v| v.validator_id == id }
      raise "验证器不存在: '#{id}'" unless validator
      
      validator
    end
  end
end
