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
  VALIDATED_SCHEMA_VERSION = '2026_02_05_115551'
  
  # 关联表完整性规则 - 定义必需的关联关系
  # 格式: { 主表 => [{ association: 关联名, model: 关联模型, required: 是否必需, description: 说明 }] }
  ASSOCIATION_RULES = {
    'Ticket' => [
      { 
        association: :ticket_suppliers, 
        model: 'TicketSupplier', 
        required: true, 
        description: '门票必须关联至少1个供应商（用户购买时需选择供应商）',
        min_count: 1,
        check_fields: { current_price: '供应商价格不能为空', stock: '库存信息必须设置（-1表示无限库存）' }
      }
    ],
    'Hotel' => [
      { 
        association: :hotel_rooms, 
        model: 'HotelRoom', 
        required: true, 
        description: '酒店必须关联至少1个房型（用户预订时需选择房型）',
        min_count: 1,
        check_fields: { price: '房型价格不能为空', room_type: '房型类型不能为空' }
      }
    ],
    'Flight' => [
      { 
        association: :flight_offers, 
        model: 'FlightOffer', 
        required: false,  # FlightOffer 不是必需的（可以使用 Flight.price）
        description: '航班可以有多个套餐优惠（非必需，但推荐创建）',
        min_count: 0,
        check_fields: { price: '套餐价格不能为空' }
      }
    ],
    'Attraction' => [
      { 
        association: :tickets, 
        model: 'Ticket', 
        required: false,  # 有些景点可能是免费的，没有门票
        description: '景点可以有门票（如果 is_free=false 则应该有门票）',
        min_count: 0,
        conditional: ->(record) { !record.is_free }  # 仅对收费景点要求
      }
    ]
  }.freeze
  
  # 业务规则验证 - 检查关键业务字段
  BUSINESS_RULES = {
    'TicketSupplier' => [
      { field: :current_price, rule: ->(val) { val.present? && val > 0 }, message: 'current_price 必须大于0' },
      { field: :stock, rule: ->(val) { val.present? && (val > 0 || val == -1) }, message: 'stock 必须大于0或为-1（无限库存）' }
    ],
    'HotelRoom' => [
      { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' },
      { field: :room_type, rule: ->(val) { val.present? }, message: 'room_type 不能为空' }
    ],
    'FlightOffer' => [
      { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' }
    ],
    'Ticket' => [
      { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' }
    ],
    'Hotel' => [
      { field: :price, rule: ->(val) { val.present? && val >= 0 }, message: 'price 不能为空（可以为0但必须有值）' }
    ],
    'Flight' => [
      { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' },
      { field: :available_seats, rule: ->(val) { val.present? && val >= 0 }, message: 'available_seats 不能为空' }
    ]
  }.freeze
  
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
    
    # 去重并排除系统表和非模型类
    models.uniq.reject { |m| system_model?(m) || non_model_class?(m) }
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
  
  # 判断是否为非模型类（Ruby标准类、Gem类等）
  def non_model_class?(model_name)
    # 常见的非模型类：Ruby标准库、Gem类、工具类
    non_models = %w[
      BCrypt
      Password
      Date
      Time
      DateTime
      String
      Integer
      Float
      Array
      Hash
      File
      Dir
      JSON
      YAML
      Rails
      ActiveRecord
      ActiveSupport
      ActionCable
      ImageSeedHelper
      DataVersionable
    ]
    non_models.include?(model_name)
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
    
    # 5. 检查关联表完整性（根据 ASSOCIATION_RULES）
    association_errors = validate_associations(model_class, records)
    errors.concat(association_errors)
    
    # 6. 检查业务规则（根据 BUSINESS_RULES）
    business_errors = validate_business_rules(model_class, records)
    errors.concat(business_errors)
    
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
  
  # 验证关联表完整性（检查必需的关联是否存在）
  # 这是解决 V259 问题的核心：确保 Ticket 有 TicketSupplier，Hotel 有 HotelRoom 等
  def validate_associations(model_class, records)
    errors = []
    model_name = model_class.name
    
    # 检查是否有关联规则定义
    rules = ASSOCIATION_RULES[model_name]
    return errors unless rules
    
    # 抽样检查前 5 条记录
    sample_records = records.limit(5)
    
    rules.each do |rule|
      association_name = rule[:association]
      required = rule[:required]
      min_count = rule[:min_count] || (required ? 1 : 0)
      description = rule[:description]
      check_fields = rule[:check_fields] || {}
      conditional = rule[:conditional]  # 条件检查（可选）
      
      # 检查模型是否定义了此关联
      unless model_class.reflect_on_association(association_name)
        errors << "⚠️  #{model_name} 模型未定义关联 :#{association_name}（配置可能有误）"
        next
      end
      
      # 统计有多少记录缺少关联
      missing_count = 0
      missing_examples = []
      
      sample_records.each do |record|
        # 如果有条件检查，先判断是否需要此关联
        if conditional && !conditional.call(record)
          next  # 不满足条件，跳过检查
        end
        
        associated_records = record.send(association_name)
        count = associated_records.is_a?(ActiveRecord::Relation) ? associated_records.count : (associated_records ? 1 : 0)
        
        if count < min_count
          missing_count += 1
          missing_examples << { id: record.id, name: record.try(:name) || 'N/A', count: count }
        end
        
        # 检查关联记录的必需字段
        if count > 0 && check_fields.any?
          associated_records = [associated_records] unless associated_records.is_a?(ActiveRecord::Relation)
          associated_records.each do |assoc_record|
            check_fields.each do |field, message|
              value = assoc_record.send(field)
              if value.nil? || (value.respond_to?(:empty?) && value.empty?) || (value.is_a?(Numeric) && value == 0 && field != :stock)
                errors << "❌ #{model_name}(ID:#{record.id}) 的关联 #{rule[:model]}(ID:#{assoc_record.id}) #{message}"
              end
            end
          end
        end
      end
      
      # 如果必需关联缺失，报告错误
      if required && missing_count > 0
        errors << "❌ #{model_name} 缺少必需关联 #{rule[:model]}：#{missing_count}/#{sample_records.count} 条记录缺失（#{description}）"
        missing_examples.first(3).each do |example|
          errors << "   → 示例: ID=#{example[:id]}, 名称=#{example[:name]}, 关联数=#{example[:count]}"
        end
        
        # 提供修复建议
        errors << "   💡 修复建议: 在数据包中为 #{model_name} 创建关联的 #{rule[:model]} 记录"
        errors << "   💡 参考: 查看 app/validators/support/data_packs/v1/attractions.rb 中的 TicketSupplier 创建示例"
      end
    end
    
    errors
  rescue StandardError => e
    ["#{model_class.name} 关联验证出错: #{e.message}"]
  end
  
  # 验证业务规则（检查关键业务字段的有效性）
  def validate_business_rules(model_class, records)
    errors = []
    model_name = model_class.name
    
    # 检查是否有业务规则定义
    rules = BUSINESS_RULES[model_name]
    return errors unless rules
    
    # 抽样检查前 3 条记录
    sample_records = records.limit(3)
    
    sample_records.each_with_index do |record, index|
      rules.each do |rule|
        field = rule[:field]
        validation_rule = rule[:rule]
        message = rule[:message]
        
        # 检查字段是否存在
        unless record.respond_to?(field)
          next  # 字段不存在，跳过检查
        end
        
        value = record.send(field)
        
        # 执行验证规则
        unless validation_rule.call(value)
          errors << "❌ #{model_name} 记录业务规则违反（样本 #{index + 1}，ID: #{record.id}）: #{message}（当前值: #{value.inspect}）"
        end
      end
    end
    
    errors
  rescue StandardError => e
    ["#{model_class.name} 业务规则验证出错: #{e.message}"]
  end
end
