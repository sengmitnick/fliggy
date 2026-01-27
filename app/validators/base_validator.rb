# frozen_string_literal: true

# 条件加载 RSpec（仅在开发/测试环境可用）
begin
  require 'rspec/expectations'
  require 'rspec/matchers'
  RSPEC_AVAILABLE = true
rescue LoadError
  RSPEC_AVAILABLE = false
end

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
  # 仅在 RSpec 可用时 include
  include RSpec::Matchers if RSPEC_AVAILABLE
  
  # 自定义异常类（用于生产环境）
  class ExpectationNotMetError < StandardError
    def initialize(message)
      super(message)
    end
  end
  
  # 简单的 ExpectationTarget 实现（用于生产环境）
  class ExpectationTarget
    def initialize(actual)
      @actual = actual
    end
    
    def to(matcher = nil, *args, &block)
      if matcher.nil?
        # 返回一个 MatcherProxy 对象，支持链式调用
        MatcherProxy.new(@actual)
      else
        # 直接调用匹配器
        matcher.call(@actual, *args, &block)
      end
    end
  end
  
  # MatcherProxy 类，提供各种匹配器方法
  class MatcherProxy
    def initialize(actual)
      @actual = actual
    end
    
    def eq(expected, message = nil)
      unless @actual == expected
        error_msg = message || "expected: #{expected.inspect}\n     got: #{@actual.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def match(pattern, message = nil)
      unless @actual.to_s.match?(pattern)
        error_msg = message || "expected: #{@actual.inspect} to match #{pattern.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def be
      ComparisonProxy.new(@actual)
    end
    
    def be_true(message = nil)
      unless @actual == true
        error_msg = message || "expected: true\n     got: #{@actual.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def be_false(message = nil)
      unless @actual == false
        error_msg = message || "expected: false\n     got: #{@actual.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def be_nil(message = nil)
      unless @actual.nil?
        error_msg = message || "expected: nil\n     got: #{@actual.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def be_present(message = nil)
      if @actual.respond_to?(:present?)
        unless @actual.present?
          error_msg = message || "expected: present\n     got: #{@actual.inspect}"
          raise ExpectationNotMetError, error_msg
        end
      elsif @actual.nil? || (@actual.respond_to?(:empty?) && @actual.empty?)
        error_msg = message || "expected: present\n     got: #{@actual.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def be_empty(message = nil)
      if @actual.respond_to?(:empty?)
        unless @actual.empty?
          error_msg = message || "expected: empty\n     got: #{@actual.inspect}"
          raise ExpectationNotMetError, error_msg
        end
      else
        error_msg = message || "expected: empty\n     got: #{@actual.inspect} (does not respond to empty?)"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def include(item, message = nil)
      if @actual.respond_to?(:include?)
        unless @actual.include?(item)
          error_msg = message || "expected: #{@actual.inspect} to include #{item.inspect}"
          raise ExpectationNotMetError, error_msg
        end
      else
        error_msg = message || "expected: #{@actual.inspect} to respond to include?"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
  end
  
  # ComparisonProxy 类，处理比较运算符（be >=, be < 等）
  class ComparisonProxy
    def initialize(actual)
      @actual = actual
    end
    
    def >=(expected, message = nil)
      unless @actual >= expected
        error_msg = message || "expected: #{@actual.inspect} to be >= #{expected.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def <=(expected, message = nil)
      unless @actual <= expected
        error_msg = message || "expected: #{@actual.inspect} to be <= #{expected.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def >(expected, message = nil)
      unless @actual > expected
        error_msg = message || "expected: #{@actual.inspect} to be > #{expected.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
    
    def <(expected, message = nil)
      unless @actual < expected
        error_msg = message || "expected: #{@actual.inspect} to be < #{expected.inspect}"
        raise ExpectationNotMetError, error_msg
      end
      true
    end
  end
  
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
  
  # 子类必须实现：模拟 AI Agent 操作
  def simulate
    raise NotImplementedError, "Subclass must implement #simulate"
  end
  
  # 执行准备阶段（设置 data_version）
  def execute_prepare
    # 生成唯一的 data_version（使用随机数，确保在 32 位整数范围内）
    # PostgreSQL integer 类型范围: -2147483648 到 2147483647
    # 我们使用正数范围：1 到 2000000000
    @data_version = rand(1..2_000_000_000)
    
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
  
  # 执行完整的自动化测试流程（prepare -> simulate -> verify）
  def execute_simulate
    result = {
      validator_id: self.class.validator_id,
      title: self.class.title,
      status: 'unknown',
      prepare_info: nil,
      simulate_info: nil,
      verify_result: nil,
      timestamp: Time.current.iso8601
    }
    
    begin
      # 0. 确保基线数据已加载
      ensure_baseline_data_loaded
      
      # 1. 准备阶段
      result[:prepare_info] = execute_prepare
      
      # 2. 模拟操作阶段
      result[:simulate_info] = simulate
      
      # 3. 验证阶段
      result[:verify_result] = execute_verify
      
      # 判断最终状态
      result[:status] = result[:verify_result][:status]
      
    rescue StandardError => e
      result[:status] = 'error'
      result[:error] = e.message
      result[:backtrace] = e.backtrace.first(10)
      
      # 确保即使出错也回滚数据
      rollback_to_baseline if @data_version
    end
    
    result
  end
  
  private
  
  # 确保基线数据已加载
  def ensure_baseline_data_loaded
    # 检查是否已存在基线数据（使用City作为标志）
    return if City.where(data_version: 0).exists?
    
    puts "\n" + "=" * 80
    puts "🚀 正在初始化验证器基线数据 (data_version=0)"
    puts "=" * 80
    
    # 设置 PostgreSQL 会话变量 app.data_version='0'
    ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '0'")
    
    # 获取数据包目录
    data_packs_dir = Rails.root.join('app/validators/support/data_packs/v1')
    
    unless Dir.exist?(data_packs_dir)
      raise "Data packs directory not found: #{data_packs_dir}"
    end
    
    # 获取所有 .rb 文件并按文件名排序
    data_pack_files = Dir.glob(data_packs_dir.join('*.rb')).sort
    
    # 确保 base.rb 优先加载（如果存在）
    base_file = data_packs_dir.join('base.rb')
    if File.exist?(base_file)
      data_pack_files.delete(base_file.to_s)
      data_pack_files.unshift(base_file.to_s)
    end
    
    # 加载所有数据包
    data_pack_files.each do |file|
      filename = File.basename(file)
      puts "  → 加载 #{filename}"
      begin
        load file
      rescue StandardError => e
        puts "  ✗ 加载失败: #{filename}"
        puts "    错误: #{e.message}"
        raise e  # 在 simulate 阶段应该直接失败，而不是忽略错误
      end
    end
    
    puts "=" * 80
    puts "✓ 基线数据初始化完成 (data_version=0)"
    puts "  - 共加载 #{data_pack_files.size} 个数据包"
    puts "  - City 数量: #{City.where(data_version: 0).count}"
    puts "  - Flight 数量: #{Flight.where(data_version: 0).count}"
    puts "  - User 数量: #{User.where(data_version: 0).count}"
    puts "=" * 80
    puts ""
  end
  
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
    rescue (RSPEC_AVAILABLE ? RSpec::Expectations::ExpectationNotMetError : ExpectationNotMetError) => e
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
    if RSPEC_AVAILABLE
      RSpec::Expectations::ExpectationTarget.new(actual)
    else
      ExpectationTarget.new(actual)
    end
  end
end
