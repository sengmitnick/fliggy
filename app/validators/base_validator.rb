# frozen_string_literal: true

require 'rspec/expectations'
require 'rspec/matchers'

# BaseValidator 为验证任务提供 RSpec 风格的 DSL
# 
# 使用示例:
#   class MyValidator < BaseValidator
#     self.validator_id = 'my_task'
#     self.title = '任务标题'
#     
#     def prepare
#       # 准备数据和环境
#     end
#     
#     def verify
#       # 使用 expect 进行断言
#       expect(Booking.count).to eq(1)
#     end
#   end
class BaseValidator
  include RSpec::Matchers
  
  attr_reader :execution_id, :errors, :score, :assertions
  
  class << self
    attr_accessor :validator_id, :title, :description, :timeout_seconds
    
    # 返回验证器元信息
    def metadata
      {
        id: validator_id,
        title: title,
        description: description,
        timeout: timeout_seconds
      }
    end
  end
  
  # 数据包版本（当前使用 v1）
  DATA_PACK_VERSION = 'v1'
  
  def initialize(execution_id = SecureRandom.uuid)
    @execution_id = execution_id
    @errors = []
    @score = 0
    @assertions = []
    @prepare_result = nil
  end
  
  # 子类必须实现的方法
  def prepare
    raise NotImplementedError, "Subclass must implement #prepare"
  end
  
  def verify
    raise NotImplementedError, "Subclass must implement #verify"
  end
  
  # 执行准备阶段（设置 data_version）
  def execute_prepare
    # 生成唯一的 data_version（使用时间戳 + 随机数确保唯一性）
    @data_version = (Time.now.to_f * 1000000).to_i
    
    # 设置 PostgreSQL 会话变量 app.data_version
    # 使用 SET SESSION 确保连接级别作用域（不仅限于事务内）
    # RLS 策略会自动过滤查询，只返回 data_version=0（基线）+ 当前版本的数据
    # DataVersionable 的 before_create 钩子会自动读取并设置新记录的 data_version
    ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{@data_version}'")
    
    # 执行自定义准备逻辑（通常不需要加载数据，直接使用基线数据即可）
    @prepare_result = prepare
    
    # 保存执行状态（用于验证阶段恢复）
    save_execution_state
    
    @prepare_result
  end
  
  # 执行验证阶段（验证用户操作结果）
  def execute_verify
    result = {
      execution_id: @execution_id,
      status: 'unknown',
      score: 0,
      assertions: [],
      errors: []
    }
    
    begin
      # 恢复执行状态（从准备阶段保存的状态，包括 @data_version）
      restore_execution_state
      
      # 恢复 PostgreSQL 会话变量 app.data_version
      # 使用 SET SESSION 确保连接级别作用域
      # 这样查询时可以看到基线数据 + AI 创建的数据
      ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{@data_version}'")
      
      # 执行验证（直接验证现有数据，不重新加载任何数据）
      verify
      
      # 计算结果
      result[:status] = @errors.empty? ? 'passed' : 'failed'
      result[:score] = @score
      result[:assertions] = @assertions
      result[:errors] = @errors
      
    rescue StandardError => e
      result[:status] = 'error'
      result[:errors] << "验证执行出错: #{e.message}"
      result[:errors] << e.backtrace.first(5).join("\n")
    end
    
    # 清理执行状态
    cleanup_execution_state
    
    # 验证完成后，回滚到基线状态（删除当前 data_version 的所有数据）
    rollback_to_baseline
    
    result
  end
  
  private
  
  # 回滚到基线状态（删除当前 data_version 的所有数据）
  def rollback_to_baseline
    return unless @data_version
    
    puts "\nℹ️  回滚到基线状态（删除 data_version=#{@data_version} 的数据）..."
    
    # 使用 DataVersionable.models 获取所有注册的模型
    # 这样无需维护硬编码的模型列表
    DataVersionable.models.each do |model|
      begin
        deleted_count = model.where(data_version: @data_version).delete_all
        puts "  → #{model.name}: 删除 #{deleted_count} 条记录" if deleted_count > 0
      rescue StandardError => e
        puts "  ⚠️  删除 #{model.name} 失败: #{e.message}"
      end
    end
    
    puts "✓ 已回滚到基线状态（保留 data_version=0 的基线数据）"
  end
  
  # 保存执行状态到数据库
  def save_execution_state
    # 获取子类定义的状态数据
    custom_data = execution_state_data || {}
    
    # 确保 data_version 总是被保存（即使子类覆盖了 execution_state_data）
    custom_data[:data_version] = @data_version
    
    state = {
      validator_class: self.class.name,
      timestamp: Time.current.to_s,
      data: custom_data
    }
    
    # 使用数据库存储，使用 JSON 类型
    ActiveRecord::Base.connection.execute(
      "INSERT INTO validator_executions (execution_id, state, created_at, updated_at) " \
      "VALUES (#{ActiveRecord::Base.connection.quote(@execution_id)}, " \
      "#{ActiveRecord::Base.connection.quote(state.to_json)}, " \
      "NOW(), NOW()) " \
      "ON CONFLICT (execution_id) DO UPDATE SET " \
      "state = EXCLUDED.state, updated_at = NOW()"
    )
  end
  
  # 从数据库恢复执行状态
  def restore_execution_state
    result = ActiveRecord::Base.connection.execute(
      "SELECT state FROM validator_executions WHERE execution_id = #{ActiveRecord::Base.connection.quote(@execution_id)}"
    ).first
    
    raise "执行状态不存在: #{@execution_id}" unless result
    
    state = JSON.parse(result['state'])
    data = state['data'] || {}
    
    # 恢复 data_version（必须）
    @data_version = data['data_version']
    
    # 调用子类的恢复方法
    restore_from_state(data)
  end
  
  # 清理执行状态
  def cleanup_execution_state
    ActiveRecord::Base.connection.execute(
      "DELETE FROM validator_executions WHERE execution_id = #{ActiveRecord::Base.connection.quote(@execution_id)}"
    )
  end
  

  
  # 子类可覆盖：返回需要保存的状态数据
  def execution_state_data
    {
      data_version: @data_version
    }
  end
  
  # 子类可覆盖：从状态恢复实例变量
  def restore_from_state(data)
    @data_version = data['data_version']
  end
  
  # 添加断言（RSpec 风格）
  def add_assertion(name, weight:)
    assertion = { name: name, weight: weight, passed: false }
    
    begin
      yield
      assertion[:passed] = true
      @score += weight
    rescue RSpec::Expectations::ExpectationNotMetError => e
      assertion[:error] = e.message
      @errors << "#{name}: #{e.message}"
    rescue StandardError => e
      assertion[:error] = "执行错误: #{e.message}"
      @errors << "#{name}: #{e.message}"
    end
    
    @assertions << assertion
  end
  
  # 提供 RSpec 的 expect 方法
  def expect(actual)
    RSpec::Expectations::ExpectationTarget.new(actual)
  end
end
