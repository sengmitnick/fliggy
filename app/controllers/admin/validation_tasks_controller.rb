# frozen_string_literal: true

class Admin::ValidationTasksController < Admin::BaseController
  # GET /admin/validation_tasks
  def index
    @tasks = load_all_validators
  end

  # GET /admin/validation_tasks/:id
  def show
    @tasks = load_all_validators
    @task = @tasks.find { |t| t[:id] == params[:id] }
    
    if @task.nil?
      redirect_to admin_validation_tasks_path, alert: "任务不存在"
      return
    end
    
    # 查找上一个和下一个任务
    current_index = @tasks.index { |t| t[:id] == @task[:id] }
    @prev_task = @tasks[current_index - 1] if current_index && current_index > 0
    @next_task = @tasks[current_index + 1] if current_index && current_index < @tasks.length - 1
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
      begin
        klass = class_name.constantize
        next unless klass < BaseValidator
        
        # 返回验证器的 metadata
        klass.metadata
      rescue StandardError => e
        Rails.logger.error "Failed to load validator #{class_name}: #{e.message}"
        nil
      end
    end.compact
  end

  # 根据ID查找验证器
  def find_validator_by_id(id)
    load_all_validators.find { |task| task[:id] == id }
  end
end
