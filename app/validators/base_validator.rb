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
    attr_accessor :validator_id, :title, :description, :data_pack_version, :timeout_seconds
    
    # 返回验证器元信息
    def metadata
      {
        id: validator_id,
        title: title,
        description: description,
        data_pack_version: data_pack_version,
        timeout: timeout_seconds
      }
    end
  end
  
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
  
  # 执行准备阶段（在数据库事务中）
  def execute_prepare
    ActiveRecord::Base.transaction do
      # 加载数据包
      load_data_pack
      
      # 执行自定义准备逻辑
      @prepare_result = prepare
      
      # 强制回滚，不提交数据
      raise ActiveRecord::Rollback
    end
    
    # 在事务回滚后保存执行状态（这样状态会被持久化）
    save_execution_state
    
    @prepare_result
  end
  
  # 执行验证阶段（在新事务中）
  def execute_verify
    result = {
      execution_id: @execution_id,
      status: 'unknown',
      score: 0,
      assertions: [],
      errors: []
    }
    
    ActiveRecord::Base.transaction do
      begin
        # 恢复执行状态
        restore_execution_state
        
        # 重新加载数据包
        load_data_pack
        
        # 执行验证
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
      ensure
        # 总是回滚，不保留任何数据
        raise ActiveRecord::Rollback
      end
    end
    
    # 清理 Redis 状态
    cleanup_execution_state
    
    result
  end
  
  private
  
  # 从 JSON 文件加载数据包到数据库
  def load_data_pack
    data_pack_path = Rails.root.join(
      'app/validators/support/data_packs',
      "#{self.class.data_pack_version}.json"
    )
    
    unless File.exist?(data_pack_path)
      raise "Data pack not found: #{data_pack_path}"
    end
    
    data = JSON.parse(File.read(data_pack_path))
    
    # 按表名插入数据
    data.each do |table_name, records|
      model = table_name.singularize.classify.constantize
      records.each do |attrs|
        # 转换日期字符串
        attrs.each do |key, value|
          if value.is_a?(String) && value.match?(/^\d{4}-\d{2}-\d{2}$/)
            attrs[key] = Date.parse(value)
          end
        end
        model.create!(attrs)
      end
    end
  end
  
  # 保存执行状态到数据库
  def save_execution_state
    state = {
      validator_class: self.class.name,
      timestamp: Time.current.to_s,
      data: execution_state_data
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
    restore_from_state(state['data'])
  end
  
  # 清理执行状态
  def cleanup_execution_state
    ActiveRecord::Base.connection.execute(
      "DELETE FROM validator_executions WHERE execution_id = #{ActiveRecord::Base.connection.quote(@execution_id)}"
    )
  end
  
  # 子类可覆盖：返回需要保存的状态数据
  def execution_state_data
    {}
  end
  
  # 子类可覆盖：从状态恢复实例变量
  def restore_from_state(data)
    # 默认不做任何事
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
