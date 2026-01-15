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
  
  # 执行准备阶段（加载测试数据）
  def execute_prepare
    # 1. 清空测试数据表（Flight/Hotel等），保留基础数据（City等）
    reset_test_data_only
    
    # 2. 加载当前版本下的所有数据包（包括 base.rb，全量加载）
    load_all_data_packs
    
    # 3. 执行自定义准备逻辑
    @prepare_result = prepare
    
    # 4. 保存执行状态（用于验证阶段恢复）
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
      # 恢复执行状态（从准备阶段保存的状态）
      restore_execution_state
      
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
    
    # 验证完成后，回滚到 checkpoint（清空测试数据，保留 seeds）
    rollback_to_checkpoint
    
    result
  end
  
  private
  
  # 加载当前版本下的所有数据包（包括 base.rb）
  def load_all_data_packs
    data_packs_dir = Rails.root.join('app/validators/support/data_packs', DATA_PACK_VERSION)
    
    unless Dir.exist?(data_packs_dir)
      puts "\n⚠️  数据包目录不存在: #{data_packs_dir}"
      return
    end
    
    # 获取所有 .rb 文件（包括 base.rb）
    data_pack_files = Dir.glob(data_packs_dir.join('*.rb')).sort
    
    if data_pack_files.empty?
      puts "\n⚠️  未找到数据包文件（#{DATA_PACK_VERSION}）"
      return
    end
    
    puts "\n📦 正在加载 #{DATA_PACK_VERSION} 数据包..."
    data_pack_files.each do |file|
      puts "  → 加载 #{File.basename(file)}"
      load file
    end
    puts "✓ 所有数据包加载完成（#{data_pack_files.size} 个文件）"
  end
  

  
  # 回滚到初始状态（清空所有数据）
  def rollback_to_checkpoint
    puts "\nℹ️  回滚到初始状态（清空所有数据）..."
    # 清空所有表（订单 + 测试数据 + 基础数据）
    [
      # 订单相关（用户操作产生的）
      Booking, HotelBooking, TrainBooking, TourGroupBooking,
      CarOrder, BusTicketOrder, AbroadTicketOrder, InternetOrder,
      DeepTravelBooking, HotelPackageOrder,
      # 测试数据（验证器加载的）
      Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket,
      # 基础数据（也需要清空）
      City, Destination
    ].each do |model|
      if defined?(model)
        model.delete_all
        # 重置序列，避免 ID 冲突
        ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
      end
    end
    
    puts "✓ 已回滚到初始状态（数据库为空）"
  end
  
  # 清空所有测试数据表（包括基础数据），保留订单
  def reset_test_data_only
    # 清空所有测试相关的数据（包括 City/Destination/Flight/Hotel 等）
    # 不清空订单（会在验证后统一清理）
    [
      # 基础数据（也需要清空，因为会重新加载）
      City, Destination,
      # 业务数据
      Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket
    ].each do |model|
      if defined?(model)
        model.delete_all
        # 重置序列，避免 ID 冲突
        ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
      end
    end
  end
  
  # 检查数据库是否为初始状态（seed 数据未被修改）
  def database_is_pristine?
    # 这个方法现在不需要了，因为我们总是在 prepare 时重置
    false
  end
  
  # 重置数据库到初始状态（已被 reset_test_tables 替代）
  def reset_database
    # 废弃：现在使用 reset_test_tables
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
