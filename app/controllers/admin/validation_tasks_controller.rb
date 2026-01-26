# frozen_string_literal: true

class Admin::ValidationTasksController < Admin::BaseController
  # GET /admin/validation_tasks
  def index
    @tasks = load_all_validators
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
end
