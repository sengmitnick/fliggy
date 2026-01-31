# frozen_string_literal: true

class Admin::ValidationTasksController < Admin::BaseController
  # GET /admin/validation_tasks
  def index
    @tasks = load_all_validators
  end

  # GET /admin/validation_tasks/:id
  def show
    @tasks = load_all_validators
    # 优先通过 validator_id 查找（URL 友好），也支持 task_id（UUID）
    @task = @tasks.find { |t| t[:validator_id] == params[:id] || t[:task_id] == params[:id] }
    
    if @task.nil?
      redirect_to admin_validation_tasks_path, alert: "任务不存在"
      return
    end
    
    # 查找上一个和下一个任务
    current_index = @tasks.index { |t| t[:validator_id] == @task[:validator_id] }
    @prev_task = @tasks[current_index - 1] if current_index && current_index > 0
    @next_task = @tasks[current_index + 1] if current_index && current_index < @tasks.length - 1
  end

  private

  # 加载所有验证器类
  def load_all_validators
    # 自动加载 app/validators/**/*_validator.rb（支持子文件夹和命名空间）
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    
    validator_files.map do |file|
      # 跳过 base_validator.rb
      next if file.end_with?('base_validator.rb')
      
      # 从文件路径推导出完整的类名（包含命名空间）
      # 例如: app/validators/v001_v050/v001_book_budget_hotel_validator.rb
      # => V001V050::V001BookBudgetHotelValidator
      relative_path = file.gsub(Rails.root.join('app/validators/').to_s, '')
      class_path = relative_path.gsub('.rb', '').split('/')
      class_name = class_path.map(&:camelize).join('::')
      
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

  # 根据ID查找验证器（支持 validator_id 或 task_id）
  def find_validator_by_id(id)
    load_all_validators.find { |task| task[:validator_id] == id || task[:task_id] == id }
  end
end
