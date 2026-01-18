# frozen_string_literal: true

namespace :validator do
  desc "Reset baseline data (delete data_version=0 and reload data packs)"
  task reset_baseline: :environment do
    puts "\n" + "="*80
    puts "🔄 重置验证器基线数据 (data_version=0)"
    puts "="*80
    
    # Step 1: 删除所有 data_version=0 的数据
    puts "\n📦 Step 1: 删除现有基线数据..."
    deleted_counts = {}
    
    DataVersionable.models.each do |model|
      begin
        count = model.where(data_version: 0).count
        if count > 0
          deleted = model.where(data_version: 0).delete_all
          deleted_counts[model.name] = deleted
          puts "  → #{model.name}: 删除 #{deleted} 条记录"
        end
      rescue StandardError => e
        puts "  ⚠️  删除 #{model.name} 失败: #{e.message}"
      end
    end
    
    if deleted_counts.empty?
      puts "  ℹ️  没有需要删除的基线数据"
    else
      puts "\n✓ 已删除 #{deleted_counts.values.sum} 条基线数据记录"
    end
    
    # Step 2: 重新加载数据包
    puts "\n📦 Step 2: 重新加载数据包..."
    
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
        
        # 删除已加载的数据
        DataVersionable.models.each do |model|
          model.where(data_version: 0).delete_all
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
      puts "✅ 基线数据重置成功"
      puts "  - 共加载 #{loaded_files.size} 个数据包"
      puts "  - 当前时间: #{Date.current}"
      puts "  - 航班日期: #{Date.current + 3.days}（Date.current + 3.days）"
      puts "\n💡 提示: 请在每天开始工作时运行此命令，确保数据包日期与当前日期同步"
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
    
    # 加载所有 Validator
    validator_files = Dir[Rails.root.join('app/validators/*_validator.rb')]
    validators = validator_files.map do |file|
      next if file.end_with?('base_validator.rb')
      File.basename(file, '.rb').camelize.constantize
    end.compact.select { |klass| klass < BaseValidator }
    
    if validators.empty?
      puts "⚠️  No validators found"
      exit 0
    end
    
    results = []
    
    validators.each do |validator_class|
      validator_id = validator_class.validator_id
      title = validator_class.title
      
      print "#{validator_id.ljust(40)} "
      
      begin
        instance = validator_class.new(SecureRandom.uuid)
        result = instance.execute_simulate
        results << result
        
        case result[:status]
        when 'passed'
          score = result[:verify_result][:score]
          puts "✓ PASSED (#{score}/100)"
        when 'failed'
          score = result[:verify_result][:score]
          puts "✗ FAILED (#{score}/100)"
          result[:verify_result][:errors].each do |error|
            puts "    → #{error}"
          end
        when 'error'
          puts "⚠ ERROR"
          puts "    → #{result[:error]}"
        end
      rescue StandardError => e
        puts "💥 EXCEPTION"
        puts "    → #{e.message}"
        results << {
          validator_id: validator_id,
          status: 'exception',
          error: e.message
        }
      end
    end
    
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
    puts "="*70 + "\n"
    
    # 如果有失败，退出码为 1（用于 CI）
    if failed > 0 || errors > 0 || exceptions > 0
      puts "❌ Some validators failed\n"
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
      
      Dir[Rails.root.join('app/validators/*_validator.rb')].each do |file|
        next if file.end_with?('base_validator.rb')
        klass = File.basename(file, '.rb').camelize.constantize
        puts "  - #{klass.validator_id} (#{klass.title})"
      end
      
      exit 1
    end
    
    # 查找 Validator
    validator_files = Dir[Rails.root.join('app/validators/*_validator.rb')]
    validator_class = validator_files.map do |file|
      next if file.end_with?('base_validator.rb')
      klass = File.basename(file, '.rb').camelize.constantize
      klass if klass.validator_id == validator_id
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
