# frozen_string_literal: true

namespace :validator do
  desc "Reset baseline data (clear entire database and reload data packs)"
  task reset_baseline: :environment do
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
    
    # 加载所有数据包
    loaded_files = []
    data_pack_files.each do |file|
      filename = File.basename(file)
      print "  → 加载 #{filename}..."
      begin
        load file
        loaded_files << filename
        puts " ✓"
      rescue StandardError => e
        puts " ✗"
        puts "    错误: #{e.message}"
        puts "\n❌ 数据包加载失败，回滚操作..."
        
        # 删除已加载的数据（使用 destroy_all 以处理外键依赖）
        DataVersionable.models.reverse.each do |model|
          model.where(data_version: 0).destroy_all
        end
        
        exit 1
      end
    end
    
    # Step 3: 验证数据加载
    puts "\n📊 Step 3: 验证数据加载结果..."
    verification_passed = true
    
    expected_models = {
      'City' => City,
      'Flight' => Flight,
      'User' => User,
      'Passenger' => Passenger
    }
    
    expected_models.each do |name, model|
      count = model.where(data_version: 0).count
      if count > 0
        puts "  ✓ #{name}: #{count} 条记录"
      else
        puts "  ✗ #{name}: 0 条记录（预期应有数据）"
        verification_passed = false
      end
    end
    
    # 最终汇总
    puts "\n" + "="*80
    if verification_passed
      puts "✅ 基线数据重置成功（新环境初始化完成）"
      puts "  - 数据库已完全清空并重新初始化"
      puts "  - 共加载 #{loaded_files.size} 个数据包"
      puts "  - 当前时间: #{Date.current}"
      puts "\n💡 提示: 此命令模拟甲方交付新环境的初始化过程"
      puts "   请在每天开始工作时运行此命令，确保数据包日期与当前日期同步"
    else
      puts "❌ 基线数据验证失败，请检查数据包文件"
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
      puts "✅ All validators have required class attributes\n"
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
    
    # Step 3: 检查 prepare 方法是否创建数据
    puts "🔍 Step 3: Checking prepare methods for data creation violations..."
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
    
    # Step 4: 检查权重总和
    puts "🔍 Step 4: Checking weight sums..."
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
          weights: []
        }
      elsif weights.sum != 100
        weight_errors << {
          validator: validator_name,
          error: "权重总和为 #{weights.sum}，应该为 100",
          sum: weights.sum,
          weights: weights
        }
      end
    end
    
    if weight_errors.any?
      puts "\n❌ Weight Sum Errors Found:"
      puts "-" * 70
      weight_errors.each do |error|
        puts "\n#{error[:validator]}"
        puts "  Error: #{error[:error]}"
        puts "  Weights: #{error[:weights].inspect}" if error[:weights].any?
        puts "  Sum: #{error[:sum]}"
      end
      puts "-" * 70
      puts "\n❌ #{weight_errors.size} validator(s) have incorrect weight sums"
      puts "Please fix the weight sums before running simulations\n"
      exit 1
    else
      puts "✅ All validators have correct weight sums (total = 100)\n"
    end
    
    # Step 5: 运行模拟测试
    puts "🧪 Step 5: Running simulations..."
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
    
    puts "\n" + "="*70
    puts "🧪 Testing: #{validator_class.title}"
    puts "   ID: #{validator_class.validator_id}"
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
