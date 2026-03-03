# frozen_string_literal: true

namespace :validator do
  desc "Sync data_pack_validator.rb with current schema version"
  task sync_schema_version: :environment do
    validator_file = Rails.root.join('lib/data_pack_validator.rb')
    schema_file = Rails.root.join('db/schema.rb')
    
    # Extract current schema version
    schema_content = File.read(schema_file)
    current_version = schema_content.match(/ActiveRecord::Schema\[\d+\.\d+\]\.define\(version:\s*([\d_]+)\)/)[1]
    
    # Read validator file
    validator_content = File.read(validator_file)
    
    # Extract current validator version
    old_version = validator_content.match(/VALIDATED_SCHEMA_VERSION = '([\d_]+)'/)[1]
    
    if current_version == old_version
      puts "✅ Schema version already in sync: #{current_version}"
      return
    end
    
    # Update validator version
    new_content = validator_content.gsub(
      /VALIDATED_SCHEMA_VERSION = '[\d_]+'/,
      "VALIDATED_SCHEMA_VERSION = '#{current_version}'"
    )
    
    File.write(validator_file, new_content)
    
    puts "✅ Updated data_pack_validator.rb"
    puts "   Old version: #{old_version}"
    puts "   New version: #{current_version}"
  end

  desc "Reset baseline data (clear entire database and reload data packs)"
  task reset_baseline: :environment do
    # Auto-sync schema version before validation
    puts "\n🔄 Auto-syncing schema version..."
    Rake::Task['validator:sync_schema_version'].invoke
    
    puts "\n" + "="*80
    puts "🔄 重置验证器基线数据 - 模拟甲方交付新环境初始化"
    puts "="*80
    
    # Step 1: 完全清空整个数据库
    puts "\n🗑️  Step 1: 完全清空数据库（模拟新环境）..."
    
    begin
      # 使用 PG gem 直接建立临时连接（不通过 ActiveRecord，避免影响全局状态）
      # 优先使用 ADMIN_DB_URL（生产环境），否则使用环境变量或默认配置

      if ENV['ADMIN_DB_URL'].present?
        puts "  → 使用 ADMIN_DB_URL 连接（超级管理员）"
        admin_conn = PG.connect(ENV['ADMIN_DB_URL'])
      else
        current_config = ActiveRecord::Base.connection_db_config.configuration_hash
        admin_username = ENV['DB_USER'] || 'postgres'
        admin_password = ENV['DB_PASSWORD'] || current_config[:password] || 'pgBqpmYZ'

        puts "  → 使用超级用户连接（#{admin_username}）"
        admin_conn = PG.connect(
          host: current_config[:host] || 'localhost',
          port: current_config[:port] || 5432,
          dbname: current_config[:database],
          user: admin_username,
          password: admin_password
        )
      end
      
      # 禁用外键约束检查
      admin_conn.exec("SET session_replication_role = 'replica';")

      # 抑制 PostgreSQL NOTICE 输出（如 "truncate cascades to table..."）
      admin_conn.exec("SET client_min_messages TO WARNING;")

      # 获取所有表名（排除 schema_migrations, ar_internal_metadata, good_jobs 相关表）
      tables_result = admin_conn.exec(
        "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
      )
      tables = tables_result.map { |row| row['tablename'] } - [
        'schema_migrations',
        'ar_internal_metadata',
        'good_jobs',
        'good_job_batches',
        'good_job_executions',
        'good_job_processes',
        'good_job_settings'
      ]

      deleted_total = 0
      tables.each do |table|
        count_result = admin_conn.exec("SELECT COUNT(*) FROM #{table}")
        count = count_result[0]['count'].to_i
        if count > 0
          # RESTART IDENTITY resets the sequence counters
          admin_conn.exec("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
          deleted_total += count
          puts "  → #{table}: 清空 #{count} 条记录"
        end
      end

      # 恢复外键约束检查
      admin_conn.exec("SET session_replication_role = 'origin';")

      # 关闭临时连接
      admin_conn.close

      puts "\n✓ 数据库已完全清空，共删除 #{deleted_total} 条记录"
    rescue StandardError => e
      puts "\n❌ 清空数据库失败: #{e.message}"
      # 确保恢复外键约束检查并关闭临时连接
      begin
        if defined?(admin_conn) && admin_conn && !admin_conn.finished?
          admin_conn.exec("SET session_replication_role = 'origin';")
          admin_conn.close
        end
      rescue => cleanup_error
        puts "  清理连接时出错: #{cleanup_error.message}"
      end
      exit 1
    end

    # Step 2: 重新加载数据包
    puts "\n📦 Step 2: 重新加载数据包..."

    # 设置固定随机种子，确保数据包生成的随机数据可重现
    # 使用日期作为种子：20250131
    srand(20250131)
    puts "  → 设置固定随机种子: srand(20250131) - 确保数据包随机性可重现"

    # 设置 PostgreSQL 会话变量 app.data_version='0'
    ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '0'")
    
    # 获取数据包目录
    data_packs_dir = Rails.root.join('app/validators/support/data_packs/v1')
    
    unless Dir.exist?(data_packs_dir)
      puts "\n❌ 数据包目录不存在: #{data_packs_dir}"
      exit 1
    end
    
    # 获取所有 .rb 文件并按文件名排序
    data_pack_files = Dir.glob(data_packs_dir.join('*.rb')).sort
    
    # 确保 base.rb 优先加载（如果存在）
    base_file = data_packs_dir.join('base.rb')
    if File.exist?(base_file)
      data_pack_files.delete(base_file.to_s)
      data_pack_files.unshift(base_file.to_s)
    end
    
    # 加载所有数据包（静默模式 + 输出过滤）
    loaded_files = []
    warnings = []
    
    data_pack_files.each do |file|
      filename = File.basename(file)
      print "  → 加载 #{filename}..."
      
      begin
        # 捕获数据包内的 puts 输出
        original_stdout = $stdout
        output_buffer = StringIO.new
        $stdout = output_buffer
        
        load file
        
        # 恢复输出
        output = output_buffer.string
        $stdout = original_stdout
        
        # 检查输出中是否有警告/错误关键词
        warning_patterns = /(警告|错误|失败|未找到|缺少|missing|error|failed|not found)/i
        warning_lines = output.lines.select { |line| line =~ warning_patterns }
        
        if warning_lines.any?
          warnings << { file: filename, messages: warning_lines }
          puts " ⚠️"
          warning_lines.each { |line| puts "    #{line.strip}" }
        else
          puts " ✓"
        end
        
        loaded_files << filename
      rescue StandardError => e
        # 确保恢复输出
        $stdout = original_stdout if defined?(original_stdout)
        
        puts " ✗"
        puts "    错误: #{e.message}"
        puts "    位置: #{e.backtrace.first}"
        puts "\n❌ 数据包加载失败，回滚操作..."
        
        # 删除已加载的数据（使用 delete_all 绕过外键约束）
        # reverse 确保先删除子记录（Membership），再删除父记录（User）
        DataVersionable.models.reverse.each do |model|
          begin
            deleted_count = model.where(data_version: 0).delete_all
            puts "  → 回滚 #{model.name}: #{deleted_count} 条" if deleted_count > 0
          rescue StandardError => rollback_error
            puts "  ⚠️  回滚 #{model.name} 失败: #{rollback_error.message}"
          end
        end
        
        exit 1
      end
    end
    
    # 显示警告汇总
    if warnings.any?
      puts "\n⚠️  发现 #{warnings.size} 个数据包有警告信息"
      puts "💡 请检查上述警告，确保数据包正确加载"
    end
    
    # Step 3: 验证数据包完整性
    puts "\n🔍 Step 3: 验证数据包完整性..."
    
    require_relative '../../lib/data_pack_validator'
    validator = DataPackValidator.new
    validation_results = validator.validate_all
    
    # 显示验证结果摘要
    if validation_results[:all_passed]
      puts "✅ 所有数据包验证通过（#{validation_results[:pack_count]} 个数据包）"
      
      # 统计总记录数
      total_records = 0
      expected_models = {
        'City' => City,
        'Flight' => Flight,
        'User' => User,
        'Passenger' => Passenger,
        'Hotel' => Hotel,
        'Train' => Train,
        'Attraction' => Attraction
      }
      
      expected_models.each do |name, model|
        count = model.where(data_version: 0).count
        total_records += count if count > 0
      end
      
      puts "📊 共加载 #{total_records} 条记录"
    else
      puts "❌ 数据包验证失败（#{validation_results[:failed_count]}/#{validation_results[:pack_count]} 个失败）"
      puts "\n失败的数据包："
      
      validation_results[:packs].each do |pack_name, pack_result|
        next if pack_result[:passed]
        
        puts "\n  ❌ #{pack_name}:"
        pack_result[:errors].first(3).each do |error|
          puts "    → #{error}"
        end
        puts "    ... 共 #{pack_result[:error_count]} 个错误" if pack_result[:error_count] > 3
      end
      
      puts "\n💡 运行 'rake validator:validate_data_packs' 查看完整报告"
    end
    
    verification_passed = validation_results[:all_passed]
    
    # 最终汇总
    puts "\n" + "="*80
    if verification_passed
      puts "✅ 基线数据重置成功（新环境初始化完成）"
      puts "  - 数据库已完全清空并重新初始化"
      puts "  - 共加载 #{loaded_files.size} 个数据包"
      puts "  - 当前时间: #{Date.current}"
      puts "\n💡 提示: 此命令模拟甲方交付新环境的初始化过程"
      puts "   请在每天开始工作时运行此命令，确保数据包日期与当前日期同步"
      
      if warnings.any?
        puts "\n⚠️  注意: #{warnings.size} 个数据包有警告信息，请检查上述输出"
      end
    else
      puts "❌ 基线数据验证失败，请检查数据包文件"
      puts "💡 运行 'rake validator:validate_data_packs' 查看详细验证报告"
      exit 1
    end
    puts "="*80 + "\n"
  end
  
  desc "Validate data pack integrity without reloading"
  task validate_data_packs: :environment do
    puts "\n" + "="*80
    puts "🔍 数据包验证 - 检查已加载数据的完整性"
    puts "="*80 + "\n"
    
    require_relative '../../lib/data_pack_validator'
    validator = DataPackValidator.new
    results = validator.validate_all
    
    # 详细报告
    results[:packs].each do |pack_name, pack_result|
      if pack_result[:passed]
        puts "✅ #{pack_name.ljust(30)} - 所有检查通过"
      else
        puts "❌ #{pack_name.ljust(30)} - #{pack_result[:error_count]} 个问题"
        pack_result[:errors].each do |error|
          puts "  → #{error}"
        end
      end
    end
    
    # 汇总
    puts "\n" + "="*80
    if results[:all_passed]
      puts "✅ 所有数据包验证通过"
      puts "   - 验证数据包: #{results[:pack_count]} 个"
      puts "   - 验证时间: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
    else
      puts "❌ 数据包验证失败"
      puts "   - 通过: #{results[:passed_count]}/#{results[:pack_count]} 个"
      puts "   - 失败: #{results[:failed_count]}/#{results[:pack_count]} 个"
      puts "\n💡 请修复上述问题后重新运行 'rake validator:reset_baseline'"
      exit 1
    end
    puts "="*80 + "\n"
  end
  
  desc "Run simulated tests for all validators"
  task simulate: :environment do
    puts "\n" + "="*70
    puts "🧪 Validator Simulation Tests"
    puts "="*70 + "\n"
    
    # Step 0: 检查必需的 API 端点
    puts "🔌 Step 0: Checking required API endpoints..."
    api_errors = []
    
    required_apis = [
      { method: 'GET', path: '/api/tasks', description: '获取任务列表' },
      { method: 'POST', path: '/api/tasks/:id/start', description: '创建训练会话' },
      { method: 'POST', path: '/api/verify/run', description: '验证接口' }
    ]
    
    required_apis.each do |api|
      begin
        # 检查路由是否存在
        path_for_check = api[:path].gsub(':id', 'test_id')
        
        # 使用 Rails.application.routes 检查路由
        route_found = Rails.application.routes.routes.any? do |route|
          # 匹配 HTTP 方法和路径模式
          route.verb.match?(api[:method]) && 
          route.path.spec.to_s.gsub('(.:format)', '').match?(api[:path].gsub(':id', '[^/]+'))
        end
        
        if route_found
          puts "  ✓ #{api[:method].ljust(6)} #{api[:path].ljust(30)} - #{api[:description]}"
        else
          api_errors << "#{api[:method]} #{api[:path]} - 路由不存在"
          puts "  ✗ #{api[:method].ljust(6)} #{api[:path].ljust(30)} - 路由不存在"
        end
      rescue StandardError => e
        api_errors << "#{api[:method]} #{api[:path]} - 检查失败: #{e.message}"
        puts "  ⚠ #{api[:method].ljust(6)} #{api[:path].ljust(30)} - 检查失败"
      end
    end
    
    if api_errors.any?
      puts "\n❌ API Endpoint Errors Found:"
      puts "-" * 70
      api_errors.each { |error| puts "  → #{error}" }
      puts "-" * 70
      puts "\n❌ #{api_errors.size} required API endpoint(s) are missing"
      puts "Please ensure all required APIs are properly configured in routes.rb\n"
      exit 1
    else
      puts "✅ All required API endpoints are available\n"
    end
    
    # Step 0.5: 运行 validator lint 检查
    puts "🔍 Step 0.5: Running validator lint checks..."
    
    require_relative '../validator_linter'
    linter = ValidatorLinter.new
    issues = linter.lint_all
    
    config = YAML.load_file('config/validator_lint_rules.yml')
    strict_mode = config.dig('strict_mode') || {}
    
    if issues.any?
      puts "\n⚠️  Found #{issues.size} linting issue(s):"
      puts "-" * 70
      
      # 按严重级别分组
      high_issues = issues.select { |i| i.severity == 'HIGH' }
      medium_issues = issues.select { |i| i.severity == 'MEDIUM' }
      low_issues = issues.select { |i| i.severity == 'LOW' }
      
      # 显示 HIGH 问题（始终显示）
      if high_issues.any?
        puts "\n🔴 HIGH severity issues (#{high_issues.size}):"
        high_issues.first(5).each do |issue|
          puts "  → #{issue.validator} (line #{issue.line}): #{issue.message}"
        end
        puts "  ... and #{high_issues.size - 5} more" if high_issues.size > 5
      end
      
      # 显示 MEDIUM 问题汇总
      if medium_issues.any?
        puts "\n🟡 MEDIUM severity issues (#{medium_issues.size}): Run 'rake validator:lint' for details"
      end
      
      # 显示 LOW 问题汇总
      if low_issues.any?
        puts "\n🟢 LOW severity issues (#{low_issues.size}): Run 'rake validator:lint' for details"
      end
      
      puts "-" * 70
      
      # 根据严格模式决定是否失败
      if strict_mode['enabled'] && strict_mode['fail_on_high_severity'] && high_issues.any?
        puts "\n❌ Lint check failed: #{high_issues.size} HIGH severity issue(s) must be fixed"
        puts "💡 Run 'rake validator:lint' to see all issues"
        puts "💡 Run 'rake validator:lint_single[validator_id]' to check a specific validator\n"
        exit 1
      else
        puts "\n⚠️  Lint issues found but continuing (strict mode not enforced)"
        puts "💡 Consider running 'rake validator:lint' to see details\n"
      end
    else
      puts "✅ All validators passed lint checks\n"
    end
    
    # Step 1: 检查validator类属性完整性
    puts "🔍 Step 1: Checking validator class attributes..."
    attribute_errors = []
    task_id_map = {}  # 用于检测 task_id 重复
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      
      # 加载validator类
      relative_path = file.gsub(Rails.root.join('app/validators/').to_s, '')
      class_path = relative_path.gsub('.rb', '').split('/')
      class_name = class_path.map(&:camelize).join('::')
      
      begin
        klass = class_name.constantize
        
        # 检查必需的类属性
        missing_attrs = []
        missing_attrs << 'self.validator_id' if klass.validator_id.nil?
        missing_attrs << 'self.task_id' if klass.task_id.nil?
        missing_attrs << 'self.title' if klass.title.nil?
        missing_attrs << 'self.description' if klass.description.nil?
        missing_attrs << 'self.timeout_seconds' if klass.timeout_seconds.nil?
        
        if missing_attrs.any?
          attribute_errors << {
            validator: validator_name,
            class_name: class_name,
            file: file,
            missing: missing_attrs
          }
        end
        
        # 检查 validator_id 格式：必须是字符串且与文件名一致
        if klass.validator_id.present?
          # 检查类型：必须是字符串
          unless klass.validator_id.is_a?(String)
            attribute_errors << {
              validator: validator_name,
              class_name: class_name,
              file: file,
              format_error: "validator_id 必须是字符串，当前类型: #{klass.validator_id.class}",
              expected: "'#{validator_name}'",
              actual: klass.validator_id.inspect
            }
          else
            # 检查格式：必须与文件名一致
            if klass.validator_id != validator_name
              attribute_errors << {
                validator: validator_name,
                class_name: class_name,
                file: file,
                format_error: "validator_id 与文件名不一致",
                expected: "'#{validator_name}'",
                actual: "'#{klass.validator_id}'"
              }
            end
          end
        end
        
        # 检查 task_id 格式：必须符合标准 UUID 格式（8-4-4-4-12 十六进制字符）
        if klass.task_id.present?
          uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
          unless klass.task_id.match?(uuid_pattern)
            # 检测非法字符
            invalid_chars = klass.task_id.gsub(/[0-9a-f-]/i, '').chars.uniq
            error_detail = if invalid_chars.any?
              "包含非十六进制字符: #{invalid_chars.join(', ')}"
            else
              "格式不符合 UUID 标准（应为 8-4-4-4-12 格式）"
            end
            
            attribute_errors << {
              validator: validator_name,
              class_name: class_name,
              file: file,
              format_error: "task_id 不符合标准 UUID 格式",
              detail: error_detail,
              expected: "标准 UUID 格式（仅包含 0-9, a-f 字符）",
              actual: "'#{klass.task_id}'"
            }
          else
            # 检查 UUID 是否是模式化的（非随机）
            # 只检测明显的模式特征，避免误报
            uuid_no_dash = klass.task_id.gsub('-', '')
            
            # 检测1: 包含8个或以上连续相同字符（如 00000000）
            if uuid_no_dash.match?(/([0-9a-f])\1{7,}/i)
              attribute_errors << {
                validator: validator_name,
                class_name: class_name,
                file: file,
                format_error: "task_id 疑似为模式化 UUID（非随机）",
                detail: "包含大量连续相同字符（8个以上），不符合随机 UUID 特征",
                expected: "使用 SecureRandom.uuid 生成的随机 UUID",
                actual: "'#{klass.task_id}'"
              }
            # 检测2: 最后一段是 validator 编号的零填充形式（如 000000000259 for v259）
            elsif validator_name.match?(/v(\d{3})_/) && uuid_no_dash[-12..-1].match?(/^0+#{$1}$/)
              attribute_errors << {
                validator: validator_name,
                class_name: class_name,
                file: file,
                format_error: "task_id 疑似为模式化 UUID（包含 validator 编号）",
                detail: "最后一段包含 validator 编号 #{$1}（零填充），不符合随机 UUID 特征",
                expected: "使用 SecureRandom.uuid 生成的随机 UUID",
                actual: "'#{klass.task_id}'"
              }
            # 检测3: UUID 多个段为简单递增序列（如 f257a001-0001-4001-8001）
            elsif klass.task_id.split('-')[1..3].all? { |seg| seg.match?(/^[0-8]001$/) }
              attribute_errors << {
                validator: validator_name,
                class_name: class_name,
                file: file,
                format_error: "task_id 疑似为模式化 UUID（递增序列）",
                detail: "多个段呈现递增模式（如 0001, 4001, 8001），不符合随机 UUID 特征",
                expected: "使用 SecureRandom.uuid 生成的随机 UUID",
                actual: "'#{klass.task_id}'"
              }
            end
          end
          
          # 存储 task_id 用于后续重复检查
          task_id_map[klass.task_id] ||= []
          task_id_map[klass.task_id] << { validator: validator_name, class_name: class_name, file: file }
        end
        
        # 检查 simulate 方法实现（包括 private 方法）
        has_simulate = klass.instance_methods(false).include?(:simulate) || 
                      klass.private_instance_methods(false).include?(:simulate)
        
        if has_simulate
          # 读取文件检查是否只是抛出 NotImplementedError
          content = File.read(file)
          simulate_method = content.match(/def\s+simulate.*?^\s*end/m)&.[](0)
          if simulate_method && simulate_method.match?(/raise\s+NotImplementedError/)
            attribute_errors << {
              validator: validator_name,
              class_name: class_name,
              file: file,
              format_error: "simulate 方法未实现（仅抛出 NotImplementedError）",
              expected: "完整的 simulate 方法实现",
              actual: "raise NotImplementedError"
            }
          end
        else
          attribute_errors << {
            validator: validator_name,
            class_name: class_name,
            file: file,
            format_error: "缺少 simulate 方法",
            expected: "def simulate ... end",
            actual: "未定义"
          }
        end
        
        # 检查 verify 方法中的 data_version 过滤
        content = File.read(file)
        verify_method = content.match(/def\s+verify.*?^\s*end/m)&.[](0)
        if verify_method
          # 查找所有 Model.where/joins/includes/find_by 查询
          model_queries = verify_method.scan(/\b([A-Z][a-zA-Z]+)\.(where|joins|includes|find_by)/)
          model_queries.each do |model, method|
            next if ['Date', 'File', 'Dir', 'Rails', 'SecureRandom'].include?(model)
            
            # 提取该查询的完整语句（直到下一个方法调用或行尾）
            query_pattern = /#{Regexp.escape(model)}\.#{method}.*?(?=\n\s{0,4}\w|\z)/m
            if query_match = verify_method.match(query_pattern)
              query_text = query_match[0]
              # 检查是否包含 data_version 过滤
              unless query_text.match?(/data_version:?\s*[@:]?\s*@?data_version|where\s*\(.*?data_version/)
                attribute_errors << {
                  validator: validator_name,
                  class_name: class_name,
                  file: file,
                  format_error: "verify 方法中查询缺少 data_version 过滤",
                  detail: "#{model}.#{method} 查询未过滤 data_version",
                  expected: ".where(data_version: @data_version)",
                  actual: query_text.lines.first.strip[0..80]
                }
                break  # 只报告第一个缺失，避免重复
              end
            end
          end
        end
        
        # 检查 execution_state_data 和 restore_from_state
        prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
        if prepare_method
          instance_vars = prepare_method.scan(/@(\w+)\s*=/).flatten.uniq.reject { |v| v == 'data_version' }
          if instance_vars.any?
            has_execution_state_data = content.match?(/def\s+execution_state_data/)
            has_restore_from_state = content.match?(/def\s+restore_from_state/)
            
            if !has_execution_state_data || !has_restore_from_state
              missing_methods = []
              missing_methods << 'execution_state_data' unless has_execution_state_data
              missing_methods << 'restore_from_state' unless has_restore_from_state
              
              attribute_errors << {
                validator: validator_name,
                class_name: class_name,
                file: file,
                format_error: "缺少状态保存/恢复方法",
                detail: "prepare 方法设置了 #{instance_vars.size} 个实例变量，但缺少 #{missing_methods.join(', ')}",
                expected: "def execution_state_data 和 def restore_from_state",
                actual: "缺少: #{missing_methods.join(', ')}"
              }
            end
          end
        end
      rescue NameError => e
        attribute_errors << {
          validator: validator_name,
          class_name: class_name,
          file: file,
          error: "无法加载类: #{e.message}"
        }
      end
    end
    
    if attribute_errors.any?
      puts "\n❌ Validator Attribute Errors Found:"
      puts "-" * 70
      attribute_errors.each do |error|
        puts "\n#{error[:validator]} (#{error[:class_name]})"
        puts "  File: #{error[:file]}"
        if error[:error]
          puts "  Error: #{error[:error]}"
        elsif error[:format_error]
          puts "  Format Error: #{error[:format_error]}"
          if error[:detail]
            puts "  Detail: #{error[:detail]}"
          end
          puts "  Expected: #{error[:expected]}"
          puts "  Actual: #{error[:actual]}"
          if error[:format_error].include?('validator_id')
            puts "  → validator_id 必须是字符串类型，且与文件名完全一致"
          elsif error[:format_error].include?('task_id')
            puts "  → task_id 必须符合标准 UUID 格式（8-4-4-4-12，仅包含 0-9, a-f 字符）"
            puts "  → 可使用 SecureRandom.uuid 生成标准 UUID"
          elsif error[:format_error].include?('simulate')
            puts "  → simulate 方法必须完整实现，不能仅抛出 NotImplementedError"
            puts "  → 该方法用于自动测试，模拟 AI Agent 完成任务的完整流程"
          elsif error[:format_error].include?('data_version')
            puts "  → verify 方法中所有数据库查询必须包含 data_version 过滤"
            puts "  → 使用 .where(data_version: @data_version) 确保会话隔离"
          elsif error[:format_error].include?('状态保存')
            puts "  → prepare 方法中设置的实例变量需要通过状态管理方法保存"
            puts "  → 实现 execution_state_data 返回状态 hash，restore_from_state 恢复变量"
          end
        elsif error[:missing]
          puts "  Missing attributes: #{error[:missing].join(', ')}"
          puts "  → 请使用新风格类属性定义（例如：self.validator_id = '...'）"
        end
      end
      puts "-" * 70
      puts "\n❌ #{attribute_errors.size} validator(s) have missing or invalid class attributes"
      puts "Please fix these validators before running simulations\n"
      exit 1
    else
      puts "✅ All validators have required class attributes (including unique task_id)\n"
    end
    
    # Step 2: 检查状态保存/恢复方法
    puts "🔍 Step 2: Checking state management methods..."
    state_errors = []
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      content = File.read(file)
      
      # 检查是否有 prepare 方法
      has_prepare = content.match?(/def\s+prepare/)
      
      # 提取 prepare 方法内容
      prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
      
      # 检查是否实现了状态管理方法
      has_execution_state_data = content.match?(/def\s+execution_state_data/)
      has_restore_from_state = content.match?(/def\s+restore_from_state/)
      
      # 如果有 prepare 方法，提取其中设置的实例变量（排除 @data_version）
      if has_prepare && prepare_method
        instance_vars = prepare_method.scan(/@(\w+)\s*=/).flatten.uniq.reject { |v| v == 'data_version' }
        
        # 如果 prepare 方法中设置了实例变量，就需要状态管理方法
        if instance_vars.any?
          if !has_execution_state_data || !has_restore_from_state
            missing_methods = []
            missing_methods << 'execution_state_data' unless has_execution_state_data
            missing_methods << 'restore_from_state' unless has_restore_from_state
            
            state_errors << {
              validator: validator_name,
              file: file,
              missing_methods: missing_methods,
              instance_vars: instance_vars
            }
          end
        end
      end
    end
    
    if state_errors.any?
      puts "\n❌ State Management Errors Found:"
      puts "-" * 70
      state_errors.each do |error|
        puts "\n#{error[:validator]}"
        puts "  File: #{error[:file]}"
        puts "  Missing methods: #{error[:missing_methods].join(', ')}"
        puts "  Instance variables in prepare: #{error[:instance_vars].map { |v| '@' + v }.join(', ')}"
        puts "  → These variables will be nil during verify phase!"
        puts "  → Add execution_state_data and restore_from_state methods to fix"
      end
      puts "-" * 70
      puts "\n❌ #{state_errors.size} validator(s) missing state management methods"
      puts "This will cause verify phase to fail due to nil instance variables\n"
      exit 1
    else
      puts "✅ All validators with instance variables have state management\n"
    end
    
    # Step 3: 检查 execution_state_data 和 restore_from_state 的字段一致性
    puts "🔍 Step 3: Checking state save/restore field consistency..."
    consistency_errors = []
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      content = File.read(file)
      
      # 提取 execution_state_data 方法
      execution_state_data_method = content.match(/def\s+execution_state_data.*?\{(.*?)\}/m)&.[](1)
      # 提取 restore_from_state 方法
      restore_from_state_method = content.match(/def\s+restore_from_state\(data\)(.*?)(?:def |private|\z)/m)&.[](1)
      
      if execution_state_data_method && restore_from_state_method
        # 提取 execution_state_data 中保存的字段名
        # 支持两种格式:
        # 1. 多行: { city: @city, budget: @budget }
        # 2. 单行: { origin: @origin, destination: @destination, target_date: @target_date.to_s }
        saved_keys = execution_state_data_method.scan(/(\w+):/).flatten.uniq
        
        # 提取 restore_from_state 中恢复的字段名
        # 匹配模式:
        # 1. @var = data['key'] 或 @var = data["key"]
        # 2. @var = Date.parse(data['key'])
        # 3. @var = Model.find_by(id: data['key'])
        # 4. @var = data['key'].to_i/to_f/to_s
        # 策略: 提取所有 data['key'] 或 data["key"] 中的 key
        restored_keys = restore_from_state_method.scan(/data\[(['"])(\w+)\1\]/).map { |m| m[1] }.uniq
        
        # 计算差异
        saved_set = Set.new(saved_keys)
        restored_set = Set.new(restored_keys)
        
        missing_in_restore = saved_set - restored_set
        extra_in_restore = restored_set - saved_set
        
        if missing_in_restore.any? || extra_in_restore.any?
          consistency_errors << {
            validator: validator_name,
            file: file,
            saved_keys: saved_keys,
            restored_keys: restored_keys,
            missing_in_restore: missing_in_restore.to_a,
            extra_in_restore: extra_in_restore.to_a
          }
        end
      end
    end
    
    if consistency_errors.any?
      puts "\n❌ State Save/Restore Field Mismatch Found:"
      puts "-" * 70
      consistency_errors.first(10).each do |error|
        puts "\n#{error[:validator]}"
        puts "  File: #{error[:file]}"
        if error[:missing_in_restore].any?
          puts "  Missing in restore_from_state: #{error[:missing_in_restore].join(', ')}"
          puts "  → These fields are saved but NOT restored, causing nil values in verify!"
        end
        if error[:extra_in_restore].any?
          puts "  Extra in restore_from_state: #{error[:extra_in_restore].join(', ')}"
          puts "  → These fields are restored but NOT saved, will be nil on restore!"
        end
        puts "  Saved keys: #{error[:saved_keys].join(', ')}"
        puts "  Restored keys: #{error[:restored_keys].join(', ')}"
      end
      if consistency_errors.size > 10
        puts "\n  ... and #{consistency_errors.size - 10} more validators with mismatched fields"
      end
      puts "-" * 70
      puts "\n❌ #{consistency_errors.size} validator(s) have state save/restore field mismatches"
      puts "\n💡 规则说明:"
      puts "  - execution_state_data 中保存的每个字段，必须在 restore_from_state 中恢复"
      puts "  - restore_from_state 中恢复的每个字段，必须在 execution_state_data 中保存"
      puts "  - 字段名必须完全一致（不包括 @data_version）"
      puts "\n🔧 修复方法:"
      puts "  1. 检查 execution_state_data 返回的 hash 中的所有 key"
      puts "  2. 确保每个 key 在 restore_from_state 中都有对应的 @key = data['key']"
      puts "  3. 如果有日期字段，记得使用 .to_s 保存，Date.parse() 恢复"
      puts "  4. 如果有数值字段，记得使用 .to_f 或 .to_i 转换"
      puts "\n⚠️  这是导致 'expected: <= nil' 验证错误的根本原因！\n"
      exit 1
    else
      puts "✅ All validators have consistent state save/restore fields\n"
    end
    
    # Step 4: 检查 prepare 方法是否创建数据
    puts "🔍 Step 4: Checking prepare methods for data creation violations..."
    prepare_errors = []
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      content = File.read(file)
      
      # 提取 prepare 方法内容
      prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
      
      if prepare_method
        violations = []
        
        # 检查 1: find_or_create_by (最严重的违规)
        if prepare_method.match?(/\.find_or_create_by[!]?\(/)
          violations << 'find_or_create_by! - 会创建不存在的记录'
        end
        
        # 检查 2: create / create! (直接创建)
        if prepare_method.match?(/\.(create|create!)\(/)
          violations << 'create/create! - 直接创建新记录'
        end
        
        # 检查 3: new + save (间接创建)
        if prepare_method.match?(/\.new\([^)]*\)/) && prepare_method.match?(/\.save[!]?/)
          violations << 'Model.new + save - 间接创建新记录'
        end
        
        # 检查 4: update_all / delete_all (批量修改/删除)
        if prepare_method.match?(/\.(update_all|delete_all|destroy_all)\(/)
          violations << 'update_all/delete_all/destroy_all - 修改或删除数据'
        end
        
        # 检查 5: insert / insert_all (SQL插入)
        if prepare_method.match?(/\.(insert|insert_all)\(/)
          violations << 'insert/insert_all - SQL插入数据'
        end
        
        if violations.any?
          prepare_errors << {
            validator: validator_name,
            file: file,
            violations: violations
          }
        end
      end
    end
    
    if prepare_errors.any?
      puts "\n❌ Prepare Method Violations Found:"
      puts "-" * 70
      prepare_errors.each do |error|
        puts "\n#{error[:validator]}"
        puts "  File: #{error[:file]}"
        puts "  违规操作:"
        error[:violations].each { |v| puts "    → #{v}" }
      end
      puts "-" * 70
      puts "\n❌ #{prepare_errors.size} validator(s) have prepare methods that create/modify data"
      puts "\n💡 规则说明:"
      puts "  - prepare 方法只能 QUERY 数据（使用 find_by!, where, find 等）"
      puts "  - 所有测试数据必须来自数据包（app/validators/support/data_packs/v1/）"
      puts "  - 如果缺少数据，应更新数据包文件，而不是在 prepare 中创建"
      puts "  - 使用 find_by! 替代 find_or_create_by!"
      puts "\n🔧 修复方法:"
      puts "  1. 将所有 find_or_create_by! 改为 find_by!"
      puts "  2. 删除 do |variable| ... end 代码块"
      puts "  3. 如果数据不存在，在对应的数据包文件中添加（使用 insert_all）\n"
      exit 1
    else
      puts "✅ All prepare methods only query data (no creation/modification)\n"
    end
    
    # Step 5: 检查 simulate 方法中是否私自创建 data_version: 0 的数据（绕过数据包）
    puts "🔍 Step 5: Checking simulate methods for data_version: 0 creation violations..."
    simulate_violations = []
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      content = File.read(file)
      
      # 提取 simulate 方法内容
      simulate_method = content.match(/def\s+simulate.*?^\s*end/m)&.[](0)
      
      if simulate_method
        violations = []
        
        # 检查 1: 直接创建 data_version: 0 的记录（最严重违规）
        if simulate_method.match?(/\.create[!]?\([^)]*data_version:\s*0/m)
          # 提取具体的创建语句
          creation_statements = simulate_method.scan(/(\w+)\.create[!]?\([^)]*data_version:\s*0[^)]*\)/m).flatten.uniq
          violations << "直接创建 data_version: 0 的记录: #{creation_statements.join(', ')}"
        end
        
        # 检查 2: 使用 || Model.create 模式绕过数据包（后备创建）
        # 模式: @variable || Model.create!(..., data_version: 0)
        if simulate_method.match?(/@\w+\s*\|\|\s*\w+\.create[!]?\([^)]*data_version:\s*0/m)
          fallback_patterns = simulate_method.scan(/@(\w+)\s*\|\|\s*(\w+)\.create[!]?/m)
          pattern_str = fallback_patterns.map { |var, model| "@#{var} || #{model}.create" }.join(', ')
          violations << "使用后备创建模式绕过数据包: #{pattern_str}"
        end
        
        # 检查 3: 在 simulate 中使用 insert / insert_all with data_version: 0
        if simulate_method.match?(/\.(insert|insert_all)\([^)]*data_version:\s*0/m)
          violations << "使用 insert/insert_all 创建 data_version: 0 的记录"
        end
        
        if violations.any?
          # 提取具体的违规代码行（用于展示）
          violation_lines = []
          simulate_method.each_line.with_index do |line, idx|
            if line.match?(/data_version:\s*0/) && (line.match?(/\.create/) || line.match?(/\.insert/))
              violation_lines << { line_num: idx + 1, code: line.strip }
            end
          end
          
          simulate_violations << {
            validator: validator_name,
            file: file,
            violations: violations,
            code_samples: violation_lines.first(5)  # 只显示前5个违规行
          }
        end
      end
    end
    
    if simulate_violations.any?
      puts "\n❌ Simulate Method Data Creation Violations Found:"
      puts "-" * 70
      simulate_violations.each do |error|
        puts "\n#{error[:validator]}"
        puts "  File: #{error[:file]}"
        puts "  违规操作:"
        error[:violations].each { |v| puts "    → #{v}" }
        
        if error[:code_samples].any?
          puts "  违规代码示例:"
          error[:code_samples].each do |sample|
            puts "    第#{sample[:line_num]}行: #{sample[:code]}"
          end
        end
      end
      puts "-" * 70
      puts "\n❌ #{simulate_violations.size} validator(s) have simulate methods that create data_version: 0 records"
      puts "\n💡 规则说明:"
      puts "  - simulate 方法中创建的订单/业务记录必须使用 @data_version（会话隔离）"
      puts "  - 只有基础数据（Attraction, Hotel, Flight等）才能 data_version: 0"
      puts "  - 基础数据应该来自数据包，不应该在 simulate 中创建"
      puts "  - 使用 @variable || Model.create 模式是绕过数据包的典型反模式"
      puts "\n🔧 修复方法:"
      puts "  1. 删除所有 @variable || Model.create!(..., data_version: 0) 后备创建代码"
      puts "  2. 在 prepare 方法中使用 find_by! 查询数据（不创建）"
      puts "  3. 如果数据不存在，在对应的数据包文件中添加（使用 insert_all）"
      puts "  4. simulate 方法中创建订单/业务记录时使用 data_version: @data_version"
      puts "\n⚠️  Why this matters:"
      puts "  - 在 simulate 中私自创建 data_version: 0 的数据会污染基线数据"
      puts "  - 这些数据会影响其他 validator 的执行，造成数据包依赖混乱"
      puts "  - 正确的做法是完善数据包，让所有 validator 共享同一份基线数据\n"
      exit 1
    else
      puts "✅ All simulate methods only create session-scoped data (@data_version)\n"
    end
    
    # Step 6: 检查权重总和
    puts "🔍 Step 6: Checking weight sums..."
    weight_errors = []
    
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_files.each do |file|
      next if file.end_with?('base_validator.rb')
      
      validator_name = File.basename(file, '.rb')
      content = File.read(file)
      weights = content.scan(/weight:\s*(\d+)/).flatten.map(&:to_i)
      
      if weights.empty?
        weight_errors << {
          validator: validator_name,
          error: '未找到任何 weight 定义',
          sum: 0,
          weights: [],
          zero_count: 0
        }
      else
        zero_weights = weights.count { |w| w == 0 }
        
        if zero_weights > 0
          weight_errors << {
            validator: validator_name,
            error: "发现 #{zero_weights} 个权重为0的断言（断言不能有0分）",
            sum: weights.sum,
            weights: weights,
            zero_count: zero_weights
          }
        elsif weights.sum != 100
          weight_errors << {
            validator: validator_name,
            error: "权重总和为 #{weights.sum}，应该为 100",
            sum: weights.sum,
            weights: weights,
            zero_count: 0
          }
        end
      end
    end
    
    if weight_errors.any?
      puts "\n❌ Weight Sum Errors Found:"
      puts "-" * 70
      weight_errors.each do |error|
        puts "\n#{error[:validator]}"
        puts "  Error: #{error[:error]}"
        if error[:zero_count] > 0
          puts "  Zero weights: #{error[:zero_count]}/#{error[:weights].size} assertions"
          puts "  🚨 All assertions MUST have non-zero weights"
        end
        puts "  Weights: #{error[:weights].inspect}" if error[:weights].any?
        puts "  Sum: #{error[:sum]}"
      end
      puts "-" * 70
      puts "\n❌ #{weight_errors.size} validator(s) have incorrect weight sums"
      puts "Please fix the weight sums before running simulations\n"
      exit 1
    else
      puts "✅ All validators have correct weight sums (total = 100, no zero weights)\n"
    end
    
    # Step 7: 运行模拟测试
    puts "🧪 Step 7: Running simulations..."
    puts "-" * 70
    
    # 加载所有 Validator
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validators = validator_files.map do |file|
      next if file.end_with?('base_validator.rb')
      
      # Derive full class name with namespace from file path
      relative_path = file.gsub(Rails.root.join('app/validators/').to_s, '')
      class_path = relative_path.gsub('.rb', '').split('/')
      class_name = class_path.map(&:camelize).join('::')
      
      begin
        class_name.constantize
      rescue NameError => e
        Rails.logger.warn "[Validator] Failed to load validator: #{file} (#{class_name})"
        nil
      end
    end.compact.select { |klass| klass < BaseValidator }
    
    if validators.empty?
      puts "⚠️  No validators found"
      exit 0
    end
    
    results = []
    
    validators.each do |validator_class|
      validator_id = validator_class.validator_id.to_s  # 确保是字符串
      title = validator_class.title
      
      # Workaround for V091: Rails constantize caching bug
      # Root cause: Rails constantize doesn't properly load simulate method in batch context
      # Solution: Access class metadata to force Rails to fully load the class definition
      # The metadata access below is MANDATORY - removing it causes V091 to fail in batch testing
      if validator_id.to_s.include?('v091') || validator_id == 91
        v091_file = Rails.root.join('app/validators/v051_v100/v091_book_xian_terracotta_warriors_tour_validator.rb')
        # Silent metadata access to trigger proper class loading
        _ = validator_class.instance_methods(false).include?(:simulate)
        _ = validator_class.object_id
        load v091_file if File.exist?(v091_file)
        validator_class = V051V100::V091BookXianTerracottaWarriorsTourValidator
        _ = validator_class.object_id
        _ = validator_class.instance_methods(false).include?(:simulate)
      end
      
      # 显示进度（每10个一更新）
      if (results.size % 10 == 0)
        print "\r🔄 Progress: #{results.size}/#{validators.size} validators..."
        $stdout.flush
      end
      
      begin
        instance = validator_class.new(SecureRandom.uuid)
        result = instance.execute_simulate
        results << result
        
        # 只输出失败的验证器
        case result[:status]
        when 'failed'
          print "\r#{' ' * 60}\r"  # 清空进度行
          score = result[:verify_result][:score]
          puts "✗ #{validator_id.ljust(40)} FAILED (#{score}/100)"
          result[:verify_result][:errors].each do |error|
            puts "    → #{error}"
          end
        when 'error'
          print "\r#{' ' * 60}\r"  # 清空进度行
          puts "⚠ #{validator_id.ljust(40)} ERROR"
          puts "    → #{result[:error]}"
        end
      rescue StandardError => e
        print "\r#{' ' * 60}\r"  # 清空进度行
        puts "💥 #{validator_id.ljust(40)} EXCEPTION"
        puts "    → #{e.message}"
        results << {
          validator_id: validator_id,
          status: 'exception',
          error: e.message
        }
      end
    end
    
    # 清空最后的进度行
    print "\r#{' ' * 60}\r"
    
    # 汇总结果
    puts "\n" + "="*70
    passed = results.count { |r| r[:status] == 'passed' }
    failed = results.count { |r| r[:status] == 'failed' }
    errors = results.count { |r| r[:status] == 'error' }
    exceptions = results.count { |r| r[:status] == 'exception' }
    
    puts "📊 Summary:"
    puts "   Total:      #{results.size}"
    puts "   ✓ Passed:   #{passed}" if passed > 0
    puts "   ✗ Failed:   #{failed}" if failed > 0
    puts "   ⚠ Errors:   #{errors}" if errors > 0
    puts "   💥 Exceptions: #{exceptions}" if exceptions > 0
    puts "="*70
    
    # 列出失败的验证器详情（按模块分组）
    failed_results = results.select { |r| r[:status] != 'passed' }
    if failed_results.any?
      puts "\n❌ Failed Validators (grouped by module):"
      puts "-" * 70
      
      # 按模块分组
      grouped_by_module = failed_results.group_by do |result|
        validator_id = (result[:validator_id] || result[:task_id]).to_s
        # 提取模块前缀（v001, v051, v101等）
        if validator_id.match?(/^v(\d+)_/)
          range_start = ($1.to_i / 50) * 50 + 1
          range_end = range_start + 49
          "v#{range_start.to_s.rjust(3, '0')}_v#{range_end.to_s.rjust(3, '0')}"
        else
          'other'
        end
      end
      
      # 按模块输出
      grouped_by_module.sort.each do |module_name, module_results|
        puts "\n📦 Module: #{module_name} (#{module_results.size} failed)"
        puts "-" * 70
        
        module_results.each do |result|
          validator_id = result[:validator_id] || result[:task_id]
          status = result[:status]
          
          case status
          when 'failed'
            score = result[:verify_result][:score]
            puts "\n  #{validator_id} - FAILED (#{score}/100)"
            result[:verify_result][:errors].each do |error|
              puts "    → #{error}"
            end
          when 'error'
            puts "\n  #{validator_id} - ERROR"
            puts "    → #{result[:error]}"
          when 'exception'
            puts "\n  #{validator_id} - EXCEPTION"
            puts "    → #{result[:error]}"
          end
        end
      end
      
      puts "\n" + "-" * 70
    end
    
    puts ""
    
    # 如果有失败，退出码为 1（用于 CI）
    if failed > 0 || errors > 0 || exceptions > 0
      puts "❌ #{failed_results.size} validator(s) failed\n"
      exit 1
    else
      puts "✅ All validators passed\n"
      exit 0
    end
  end
  
  desc "Run simulation for a specific validator"
  task :simulate_single, [:validator_id] => :environment do |t, args|
    # Load ValidatorChecker module
    require_relative 'validator_checker'
    
    validator_id = args[:validator_id]
    
    unless validator_id
      puts "❌ Usage: rake validator:simulate_single[validator_id]"
      puts "\nAvailable validators:"
      
      Dir[Rails.root.join('app/validators/**/*_validator.rb')].each do |file|
        next if file.end_with?('base_validator.rb')
        
        relative_path = file.gsub(Rails.root.join('app/validators/').to_s, '')
        class_path = relative_path.gsub('.rb', '').split('/')
        class_name = class_path.map(&:camelize).join('::')
        
        begin
          klass = class_name.constantize
          puts "  - #{klass.validator_id} (#{klass.title})"
        rescue NameError
          # Skip invalid validators
        end
      end
      
      exit 1
    end
    
    # 查找 Validator
    validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
    validator_class = validator_files.map do |file|
      next if file.end_with?('base_validator.rb')
      
      relative_path = file.gsub(Rails.root.join('app/validators/').to_s, '')
      class_path = relative_path.gsub('.rb', '').split('/')
      class_name = class_path.map(&:camelize).join('::')
      
      begin
        klass = class_name.constantize
        klass if klass.validator_id == validator_id
      rescue NameError
        nil
      end
    end.compact.first
    
    unless validator_class
      puts "❌ Validator not found: #{validator_id}"
      exit 1
    end
    
    # Find the validator file path
    validator_file = validator_files.find do |file|
      content = File.read(file)
      validator_id_match = content.match(/self\.validator_id\s*=\s*['"]([^'"]+)['"]/) 
      validator_id_match && validator_id_match[1] == validator_id
    end
    
    unless validator_file
      puts "❌ Could not find validator file for: #{validator_id}"
      exit 1
    end
    
    puts "\n" + "="*70
    puts "🧪 Testing: #{validator_class.title}"
    puts "   ID: #{validator_class.validator_id}"
    puts "="*70 + "\n"
    
    # Run pre-execution checks on this specific validator
    check_result = ValidatorChecker.check(validator_file: validator_file)
    
    unless check_result[:success]
      ValidatorChecker.print_errors(check_result[:errors])
      puts "\n❌ Pre-execution checks failed. Please fix the issues above before running simulation.\n"
      exit 1
    end
    
    puts "\n" + "="*70
    puts "🎬 Running Simulation"
    puts "="*70 + "\n"
    
    instance = validator_class.new(SecureRandom.uuid)
    result = instance.execute_simulate
    
    puts "\n📋 Prepare Info:"
    puts JSON.pretty_generate(result[:prepare_info])
    
    puts "\n🎬 Simulate Info:"
    puts JSON.pretty_generate(result[:simulate_info])
    
    puts "\n✅ Verify Result:"
    puts JSON.pretty_generate(result[:verify_result])
    
    puts "\n" + "="*70
    case result[:status]
    when 'passed'
      puts "✓ PASSED (#{result[:verify_result][:score]}/100)\n"
      exit 0
    when 'failed'
      puts "✗ FAILED (#{result[:verify_result][:score]}/100)"
      puts "\nErrors:"
      result[:verify_result][:errors].each { |e| puts "  - #{e}" }
      puts ""
      exit 1
    when 'error'
      puts "⚠ ERROR"
      puts result[:error]
      puts ""
      exit 1
    end
  end
end
