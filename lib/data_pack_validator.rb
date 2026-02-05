# frozen_string_literal: true

# DataPackValidator - 自动验证数据包完整性
# 
# 设计原则：
# 1. 自动扫描数据包文件，无需手动配置
# 2. 自动从 schema.rb 读取版本，检测数据库变化
# 3. 基于约定的验证规则，而非硬编码字段
#
# 验证内容：
# - 数据包文件是否成功加载（通过模型记录数量判断）
# - 必需字段是否有空值（基于数据库 NOT NULL 约束）
# - data_version 字段是否正确设置为 '0'
#
# 使用方法：
#   validator = DataPackValidator.new
#   results = validator.validate_all
#   puts results[:summary]

class DataPackValidator
  attr_reader :errors, :warnings, :schema_version, :last_validated_version
  
  DATA_PACK_DIR = Rails.root.join('app/validators/support/data_packs/v1')
  
  # Schema version constant - updated by AI when schema changes
  # This version should match db/schema.rb ActiveRecord::Schema.define(version: ...)
  VALIDATED_SCHEMA_VERSION = '2026_02_04_090615'
  
  def initialize
    @errors = []
    @warnings = []
    @schema_version = extract_schema_version
    @last_validated_version = VALIDATED_SCHEMA_VERSION
  end
  
  # 检查 schema 是否有变化
  def schema_changed?
    return true if @last_validated_version.nil?
    @schema_version != @last_validated_version
  end
  
  # 验证所有数据包
  # 返回格式：
  # {
  #   all_passed: true/false,
  #   pack_count: 总数据包数,
  #   passed_count: 通过数,
  #   failed_count: 失败数,
  #   schema_version: 当前 schema 版本,
  #   schema_changed: schema 是否变化,
  #   packs: {
  #     'pack_name' => {
  #       passed: true/false,
  #       models: [...],
  #       error_count: 错误数,
  #       errors: [错误列表]
  #     }
  #   }
  # }
  def validate_all
    # CRITICAL: Schema changes invalidate validation script itself
    # Reason: Validator logic is based on schema structure (NOT NULL constraints, column names)
    # When schema changes, the validation logic may no longer match database reality
    # Solution: AI must regenerate the entire data_pack_validator.rb script
    if schema_changed?
      puts "\n⚠️  数据库 Schema 已变化，验证脚本需要更新！"
      puts "   - 脚本中的 Schema 版本: #{@last_validated_version}"
      puts "   - 当前数据库 Schema 版本: #{@schema_version}"
      puts "\n🤖 验证脚本失效原因："
      puts "   - 新增字段未被验证"
      puts "   - 删除字段仍在检查"
      puts "   - NOT NULL 约束变化导致误报"
      puts "\n📝 解决方案（仅限 AI 操作）："
      puts "   1. 打开 lib/data_pack_validator.rb"
      puts "   2. 更新常量: VALIDATED_SCHEMA_VERSION = '#{@schema_version}'"
      puts "   3. 根据最新 schema 检查并更新验证逻辑"
      puts "   4. 重新运行此验证命令\n"
      puts "🚨 当前验证结果不可靠，终止执行\n"
      exit 1
    end

    results = {
      all_passed: true,
      pack_count: 0,
      passed_count: 0,
      failed_count: 0,
      schema_version: @schema_version,
      schema_changed: false,  # Will never reach here if schema changed
      packs: {}
    }
    
    data_pack_files.each do |file_path|
      pack_name = File.basename(file_path)
      pack_result = validate_data_pack(file_path)
      
      results[:packs][pack_name] = pack_result
      results[:pack_count] += 1
      
      if pack_result[:passed]
        results[:passed_count] += 1
      else
        results[:failed_count] += 1
        results[:all_passed] = false
      end
    end
    
    results
  end
  
  # 验证单个数据包文件
  def validate_data_pack(file_path)
    pack_name = File.basename(file_path)
    errors = []
    models_info = []
    
    # 1. 从文件中推断使用的模型
    models = infer_models_from_file(file_path)
    
    if models.empty?
      errors << "未找到任何模型插入语句（insert_all/create）"
      return {
        passed: false,
        models: [],
        error_count: errors.size,
        errors: errors
      }
    end
    
    # 2. 验证每个模型的数据完整性
    models.each do |model_name|
      begin
        model_class = model_name.constantize
        model_errors = validate_model(model_class)
        
        models_info << {
          name: model_name,
          count: model_class.where(data_version: '0').count,
          errors: model_errors
        }
        
        errors.concat(model_errors)
      rescue NameError => e
        errors << "模型 #{model_name} 不存在：#{e.message}"
      rescue StandardError => e
        errors << "验证 #{model_name} 时出错：#{e.message}"
      end
    end
    
    {
      passed: errors.empty?,
      models: models_info,
      error_count: errors.size,
      errors: errors
    }
  end
  
  private
  
  # 获取所有数据包文件
  def data_pack_files
    Dir.glob(DATA_PACK_DIR.join('*.rb')).sort
  end
  
  # 从 schema.rb 中提取版本号
  def extract_schema_version
    schema_file = Rails.root.join('db/schema.rb')
    return nil unless File.exist?(schema_file)
    
    content = File.read(schema_file)
    # Match version with underscores: 2026_02_04_090615
    match = content.match(/ActiveRecord::Schema\[\d+\.\d+\]\.define\(version:\s*([\d_]+)\)/)
    match ? match[1] : nil
  end
  
  # 从数据包文件中推断使用的模型
  # 查找所有 Model.insert_all / Model.create / Model.find_or_create_by 模式
  def infer_models_from_file(file_path)
    content = File.read(file_path)
    models = []
    
    # 匹配 Model.insert_all, Model.create, Model.find_or_create_by 等模式
    patterns = [
      /([A-Z][a-zA-Z0-9_]+)\.insert_all/,
      /([A-Z][a-zA-Z0-9_]+)\.create[(!|\(]/,
      /([A-Z][a-zA-Z0-9_]+)\.find_or_create_by/,
      /([A-Z][a-zA-Z0-9_]+)\.where.*\.update_all/
    ]
    
    patterns.each do |pattern|
      models.concat(content.scan(pattern).flatten)
    end
    
    # 去重并排除系统表
    models.uniq.reject { |m| system_model?(m) }
  end
  
  # 判断是否为系统表（不需要验证）
  def system_model?(model_name)
    system_models = %w[
      Administrator
      AdminOplog
      Session
      ActiveStorage::Blob
      ActiveStorage::Attachment
      ActiveStorage::VariantRecord
    ]
    system_models.include?(model_name)
  end
  
  # 验证单个模型的数据完整性
  def validate_model(model_class)
    errors = []
    
    # 1. 检查模型是否有 data_version 字段
    unless model_class.column_names.include?('data_version')
      errors << "#{model_class.name} 缺少 data_version 字段（业务表必须有此字段）"
      return errors
    end
    
    # 2. 检查是否有基线数据（data_version = '0'）
    records = model_class.where(data_version: '0')
    record_count = records.count
    
    if record_count == 0
      errors << "#{model_class.name} 没有基线数据（data_version='0' 的记录数为 0）"
      return errors
    end
    
    # 3. 检查必需字段是否有空值（基于数据库 NOT NULL 约束）
    required_columns = model_class.columns
      .select { |col| !col.null && col.name !~ /^(id|created_at|updated_at)$/ }
      .map(&:name)
    
    # 抽样检查前 3 条记录
    sample_records = records.limit(3)
    sample_records.each_with_index do |record, index|
      required_columns.each do |col_name|
        value = record.send(col_name)
        
        # 检查空值（nil 或空字符串）
        if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          errors << "#{model_class.name} 记录缺少必需字段 #{col_name}（样本 #{index + 1}，ID: #{record.id}）"
        end
      end
    end
    
    # 4. 检查日期范围覆盖（针对有日期字段的模型）
    date_range_result = validate_date_range_coverage(model_class, records)
    errors.concat(date_range_result[:errors])
    # 信息消息不加入 errors，单独处理（如需要可以在这里打印）
    date_range_result[:info].each { |msg| puts "  #{msg}" } if date_range_result[:info].any?
    
    errors
  rescue StandardError => e
    ["#{model_class.name} 验证过程出错: #{e.message}"]
  end
  
  # 验证日期范围覆盖（确保数据包日期范围足够大）
  # 原则：
  # 1. start_date >= Date.today-1 是刚性要求（支持西时区用户） - 必须检查并报错
  # 2. end_date 显示覆盖范围信息 - 仅供参考，不判断对错
  def validate_date_range_coverage(model_class, records)
    errors = []
    info_messages = []
    
    # 检测模型是否有日期字段（常见字段名）
    date_fields = %w[departure_time flight_date check_in_date visit_date start_date departure_date pickup_date]
    date_field = model_class.column_names.find { |col| date_fields.include?(col) }
    
    return { errors: errors, info: info_messages } unless date_field # 没有日期字段，跳过验证
    
    # 获取日期范围
    min_date = records.minimum(date_field)
    max_date = records.maximum(date_field)
    
    return { errors: errors, info: info_messages } if min_date.nil? || max_date.nil?
    
    # 转换为 Date 对象（如果是 Time/DateTime）
    min_date = min_date.to_date if min_date.respond_to?(:to_date)
    max_date = max_date.to_date if max_date.respond_to?(:to_date)
    
    # 预期范围（基于 Date.today）
    required_min = Date.today - 1.day  # 向前覆盖 1 天（西时区用户） - 刚性要求
    
    # 【刚性要求】检查最小日期是否足够早（允许 1 天误差）
    if min_date > required_min + 1.day
      errors << "❌ #{model_class.name} 日期范围不足：最小日期 #{min_date}，必须从 #{required_min}（Date.today-1）开始，以支持西时区用户"
    end
    
    # 【信息展示】显示数据覆盖的未来天数
    days_coverage = (max_date - Date.today).to_i
    info_messages << "ℹ️  #{model_class.name} 日期覆盖：#{min_date} 至 #{max_date}（未来 #{days_coverage} 天）"
    
    { errors: errors, info: info_messages }
  rescue StandardError => e
    { errors: ["#{model_class.name} 日期范围验证出错: #{e.message}"], info: [] }
  end
end
