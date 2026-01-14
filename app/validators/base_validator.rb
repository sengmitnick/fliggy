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
  
  # 执行准备阶段（加载测试数据）
  def execute_prepare
    # 1. 确保数据库处于 checkpoint 状态（有完整的 seeds 数据）
    ensure_checkpoint
    
    # 2. 清空测试数据表（Flight/Hotel等），保留 seeds 的基础数据（City等）
    reset_test_data_only
    
    # 3. 加载验证器专有的数据包（持久化，供用户操作）
    load_data_pack
    
    # 4. 执行自定义准备逻辑
    @prepare_result = prepare
    
    # 5. 保存执行状态（用于验证阶段恢复）
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
  
  # 从 Ruby seed 文件加载数据包到数据库
  # 注意：ensure_seed_loaded 和 reset_test_tables 已在 execute_prepare/execute_verify 中调用
  # 这个方法只负责执行数据包脚本
  def load_data_pack
    return unless self.class.data_pack_version
    
    # 支持两种格式：
    # 1. 版本化格式: "v1/flights" -> app/validators/support/data_packs/v1/flights.rb
    # 2. 直接文件格式: "flights_v1" -> app/validators/support/data_packs/flights_v1.rb（向后兼容）
    data_pack_path = if self.class.data_pack_version.include?('/')
                       Rails.root.join(
                         'app/validators/support/data_packs',
                         "#{self.class.data_pack_version}.rb"
                       )
                     else
                       Rails.root.join(
                         'app/validators/support/data_packs',
                         "#{self.class.data_pack_version}.rb"
                       )
                     end
    
    unless File.exist?(data_pack_path)
      raise "Data pack not found: #{data_pack_path}"
    end
    
    # 执行数据包脚本
    load data_pack_path
  end
  
  # 确保数据库处于 checkpoint 状态（完整的 seeds 数据）
  # 
  # Checkpoint = db/seeds.rb 加载完成后的状态
  # - 包含 City、Destination、Flight（seeds中的）、Hotel（seeds中的）等
  # - 这是验证器的"干净起点"
  def ensure_checkpoint
    # 检查是否已经有 checkpoint（City + Flight/Hotel 都有数据）
    # 如果 City 或 Flight 为空，说明不是 checkpoint 状态
    if City.count == 0 || Flight.count == 0
      puts "\nℹ️  数据库不在 checkpoint 状态，正在加载 seeds..."
      # 加载完整的 seeds（包括 City、Flight、Hotel 等）
      load Rails.root.join('db/seeds.rb')
      puts "✓ Checkpoint 已创建"
    else
      puts "\nℹ️  数据库已在 checkpoint 状态，跳过 seeds 加载"
    end
  end
  
  # 回滚到 checkpoint（清空测试数据和订单，保留 seeds）
  def rollback_to_checkpoint
    puts "\nℹ️  回滚到 checkpoint 状态..."
    # 清空所有验证相关的表（订单 + 测试数据）
    # 保留 City、Destination 等基础表
    [
      # 订单相关（用户操作产生的）
      Booking, HotelBooking, TrainBooking, TourGroupBooking,
      CarOrder, BusTicketOrder, AbroadTicketOrder, InternetOrder,
      DeepTravelBooking, HotelPackageOrder,
      # 测试数据（验证器加载的，非 seeds）
      Flight, FlightOffer, Train, Hotel, HotelRoom, Car, BusTicket
    ].each do |model|
      if defined?(model)
        model.delete_all
        # 重置序列，避免 ID 冲突
        ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
      end
    end
    
    # 重新加载 seeds 中的 Flight/Hotel 等数据（恢复到 checkpoint）
    load Rails.root.join('db/seeds.rb')
    puts "✓ 已回滚到 checkpoint 状态"
  end
  
  # 只清空测试数据表（Flight/Hotel等），保留订单和基础数据
  def reset_test_data_only
    # 清空业务数据（Flight/Hotel等），为加载验证器专有数据做准备
    # 不清空订单（会在验证后统一清理）
    # 不清空 City/Destination（属于 checkpoint 的一部分）
    [
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
