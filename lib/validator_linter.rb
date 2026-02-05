# frozen_string_literal: true

# ValidatorLinter - 验证器静态代码分析工具
#
# 用途：
# 1. 检测过时字段使用（stale_fields）
# 2. 检测缺失 data_version 过滤
# 3. 检测缺失 includes/joins（N+1 风险）
# 4. 检测与视图不一致的字段使用
#
# 使用方式：
#   linter = ValidatorLinter.new
#   issues = linter.lint_all
#   linter.report(issues)

require 'yaml'

class ValidatorLinter
  class Issue
    attr_reader :validator, :severity, :category, :message, :suggestion, :line, :details
    
    def initialize(validator:, severity:, category:, message:, suggestion: nil, line: nil, details: {})
      @validator = validator
      @severity = severity # HIGH, MEDIUM, LOW
      @category = category # stale_field, data_version, missing_includes, view_alignment
      @message = message
      @suggestion = suggestion
      @line = line
      @details = details
    end
    
    def to_s
      output = "[#{@severity}] #{@validator}"
      output += " (line #{@line})" if @line
      output += "\n  → #{@message}"
      output += "\n  → 建议: #{@suggestion}" if @suggestion
      output
    end
  end
  
  def initialize(config_path: 'config/validator_lint_rules.yml')
    @config_path = config_path
    @config = load_config
    @validator_files = find_validator_files
  end
  
  # 执行所有检查
  def lint_all
    issues = []
    
    puts "🔍 Scanning #{@validator_files.size} validators..."
    
    @validator_files.each do |file|
      validator_name = extract_validator_name(file)
      content = File.read(file)
      
      # 执行所有检查
      issues += check_stale_fields(validator_name, content, file)
      issues += check_data_version(validator_name, content, file)
      issues += check_missing_includes(validator_name, content, file)
      issues += check_view_alignment(validator_name, content, file)
    end
    
    issues
  end
  
  # 检查单个验证器
  def lint_single(validator_id)
    file = @validator_files.find { |f| File.basename(f, '.rb').include?(validator_id) }
    
    unless file
      puts "❌ Validator not found: #{validator_id}"
      return []
    end
    
    validator_name = extract_validator_name(file)
    content = File.read(file)
    
    issues = []
    issues += check_stale_fields(validator_name, content, file)
    issues += check_data_version(validator_name, content, file)
    issues += check_missing_includes(validator_name, content, file)
    issues += check_view_alignment(validator_name, content, file)
    
    issues
  end
  
  # 检测1: 过时字段使用
  def check_stale_fields(validator_name, content, file_path)
    issues = []
    stale_fields = @config.dig('rules', 'stale_fields') || {}
    
    stale_fields.each do |model, field_configs|
      field_configs.each do |field_config|
        field = field_config['field']
        patterns = generate_field_patterns(model, field)
        
        patterns.each do |pattern|
          if content.match?(pattern)
            # 查找具体行号
            line_number = find_line_number(content, pattern)
            
            issues << Issue.new(
              validator: validator_name,
              severity: field_config['severity'] || 'HIGH',
              category: 'stale_field',
              message: "使用了过时字段 #{model}.#{field}",
              suggestion: field_config['alternative'] || "请检查前端视图使用的实际字段",
              line: line_number,
              details: {
                model: model,
                field: field,
                reason: field_config['reason']
              }
            )
            break # 每个字段只报告一次
          end
        end
      end
    end
    
    issues
  end
  
  # 检测2: 缺失 data_version 过滤
  def check_data_version(validator_name, content, file_path)
    issues = []
    
    # 查找所有 .where(...) 调用
    where_clauses = content.scan(/^[ \t]*(\w+)\.where\([^)]*\)(?!.*data_version)/m)
    
    where_clauses.each do |match|
      model_name = match[0]
      next if model_name == 'described_class' # 跳过测试代码
      next if system_model?(model_name) # 跳过系统表
      
      # 检查是否在同一查询链中有 data_version
      line_number = find_line_number(content, /#{Regexp.escape(model_name)}\.where/)
      context = extract_context_lines(content, line_number, 3)
      
      unless context.match?(/data_version.*@data_version/)
        issues << Issue.new(
          validator: validator_name,
          severity: 'HIGH',
          category: 'data_version',
          message: "#{model_name}.where 查询缺少 data_version 过滤",
          suggestion: "添加 .where(data_version: @data_version) 确保会话隔离",
          line: line_number
        )
      end
    end
    
    issues
  end
  
  # 检测3: 缺失 includes/joins（N+1 查询风险）
  def check_missing_includes(validator_name, content, file_path)
    issues = []
    association_access = @config.dig('rules', 'common_associations') || {}
    
    association_access.each do |model, associations|
      associations.each do |assoc|
        # 检测模式：order.ticket.attraction (链式访问关联)
        pattern = /(\w+)\.#{assoc}\.(\w+)/
        
        if content.match?(pattern)
          # 检查是否有对应的 includes
          query_pattern = /#{model}\.(?:where|all|find).*\.includes\(:#{assoc}\)/m
          
          unless content.match?(query_pattern)
            line_number = find_line_number(content, pattern)
            
            issues << Issue.new(
              validator: validator_name,
              severity: 'MEDIUM',
              category: 'missing_includes',
              message: "访问 #{model}.#{assoc} 但缺少 .includes(:#{assoc})",
              suggestion: "在查询中添加 .includes(:#{assoc}) 避免 N+1 查询",
              line: line_number
            )
          end
        end
      end
    end
    
    issues
  end
  
  # 检测4: 视图对齐检查（验证器使用的字段是否在视图中存在）
  def check_view_alignment(validator_name, content, file_path)
    issues = []
    view_mappings = @config.dig('rules', 'view_field_mappings') || {}
    
    view_mappings.each do |model, mapping|
      validator_fields = mapping['validator_fields'] || []
      view_files = mapping['view_files'] || []
      
      validator_fields.each do |field|
        pattern = /#{model}.*\.#{field}/
        
        if content.match?(pattern)
          # 检查视图文件中是否使用此字段
          field_used_in_views = view_files.any? do |view_file|
            view_path = Rails.root.join(view_file)
            next false unless File.exist?(view_path)
            
            view_content = File.read(view_path)
            view_content.match?(/#{field}/)
          end
          
          unless field_used_in_views
            line_number = find_line_number(content, pattern)
            
            issues << Issue.new(
              validator: validator_name,
              severity: 'MEDIUM',
              category: 'view_alignment',
              message: "验证器使用了 #{model}.#{field}，但视图中未找到",
              suggestion: "检查前端是否使用此字段，或改用实际使用的字段",
              line: line_number,
              details: {
                checked_views: view_files
              }
            )
          end
        end
      end
    end
    
    issues
  end
  
  # 生成报告
  def report(issues)
    return success_report if issues.empty?
    
    grouped_issues = issues.group_by(&:severity)
    
    puts "\n🔍 Validator Lint Report"
    puts "=" * 60
    puts "\n❌ Found #{issues.size} issue(s):\n\n"
    
    %w[HIGH MEDIUM LOW].each do |severity|
      next unless grouped_issues[severity]
      
      puts "\n#{severity_icon(severity)} #{severity} Priority (#{grouped_issues[severity].size} issues):"
      puts "-" * 60
      
      grouped_issues[severity].each_with_index do |issue, index|
        puts "\n#{index + 1}. #{issue}"
      end
    end
    
    puts "\n" + "=" * 60
    puts "💡 Run 'rake validator:lint[validator_id]' to check a specific validator"
    puts ""
    
    issues
  end
  
  private
  
  def load_config
    unless File.exist?(@config_path)
      # 返回默认配置
      return default_config
    end
    
    YAML.load_file(@config_path)
  rescue => e
    puts "⚠️  Failed to load config from #{@config_path}: #{e.message}"
    puts "⚠️  Using default configuration"
    default_config
  end
  
  def default_config
    {
      'rules' => {
        'stale_fields' => {},
        'common_associations' => {},
        'view_field_mappings' => {}
      }
    }
  end
  
  def find_validator_files
    validator_dirs = [
      'app/validators/v001_v050',
      'app/validators/v051_v100',
      'app/validators/v101_v150',
      'app/validators/v151_v200',
      'app/validators/v201_v256'
    ]
    
    files = []
    validator_dirs.each do |dir|
      path = Rails.root.join(dir)
      next unless Dir.exist?(path)
      
      files += Dir.glob(File.join(path, '*_validator.rb')).sort
    end
    
    files
  end
  
  def extract_validator_name(file_path)
    File.basename(file_path, '.rb')
  end
  
  def generate_field_patterns(model, field)
    [
      /#{model}.*\.#{field}/,                    # Flight.discount_price
      /#{model.downcase}\.#{field}/,             # flight.discount_price
      /@\w+\.#{field}/,                          # @flight.discount_price
      /\w+\[:\w+\]\[:#{field}\]/                 # hash[:field]
    ]
  end
  
  def find_line_number(content, pattern)
    content.lines.each_with_index do |line, index|
      return index + 1 if line.match?(pattern)
    end
    nil
  end
  
  def extract_context_lines(content, line_number, context_size = 3)
    lines = content.lines
    start_line = [line_number - context_size - 1, 0].max
    end_line = [line_number + context_size - 1, lines.size - 1].min
    
    lines[start_line..end_line].join
  end
  
  def system_model?(model_name)
    system_models = %w[Administrator Session AdminOplog ValidatorExecution ActiveStorage]
    system_models.any? { |sm| model_name.include?(sm) }
  end
  
  def severity_icon(severity)
    case severity
    when 'HIGH' then '🔴'
    when 'MEDIUM' then '🟡'
    when 'LOW' then '🟢'
    else '⚪'
    end
  end
  
  def success_report
    puts "\n✅ All validators passed lint checks"
    puts "   Scanned #{@validator_files.size} validators"
    puts "   No issues found\n\n"
    []
  end
end
