# frozen_string_literal: true

# ValidatorChecker - Reusable validation logic for validators
# Used by both validator:simulate and validator:simulate_single tasks
module ValidatorChecker
  class << self
    def check(validator_file: nil)
      errors = {}
      
      if validator_file
        files = [validator_file]
        file_name = File.basename(validator_file, '.rb')
        puts "\n🔍 Checking validator: #{file_name}"
      else
        files = Dir[Rails.root.join('app/validators/**/*_validator.rb')].reject { |f| f.end_with?('base_validator.rb') }
        puts "\n🔍 Checking all validators..."
      end
      
      puts "  Step 1: Checking validator_id format..."
      step1_errors = check_validator_id_format(files)
      errors[:step1] = step1_errors if step1_errors.any?
      
      puts "  Step 2: Checking state management methods..."
      step2_errors = check_state_management(files)
      errors[:step2] = step2_errors if step2_errors.any?
      
      puts "  Step 3: Checking state save/restore field consistency..."
      step3_errors = check_state_consistency(files)
      errors[:step3] = step3_errors if step3_errors.any?
      
      puts "  Step 4: Checking prepare methods for data creation violations..."
      step4_errors = check_prepare_violations(files)
      errors[:step4] = step4_errors if step4_errors.any?
      
      puts "  Step 5: Checking simulate methods for data_version: 0 creation violations..."
      step5_errors = check_simulate_violations(files)
      errors[:step5] = step5_errors if step5_errors.any?
      
      puts "  Step 6: Checking weight sums..."
      step6_errors = check_weight_sums(files)
      errors[:step6] = step6_errors if step6_errors.any?
      
      success = errors.empty?
      
      if success
        puts "  ✅ All checks passed\n"
      else
        puts "  ❌ Found issues (see details below)\n"
      end
      
      { success: success, errors: errors }
    end
    
    def print_errors(errors)
      return if errors.empty?
      
      puts "\n" + "="*70
      puts "❌ VALIDATOR CHECKS FAILED"
      puts "="*70
      
      if errors[:step1]&.any?
        puts "\n❌ Step 1: validator_id and task_id Format Errors"
        puts "-" * 70
        errors[:step1].each do |error|
          puts "\n#{error[:validator]}"
          puts "  File: #{error[:file]}"
          
          if error[:format_error]  # task_id UUID format error
            puts "  Format Error: #{error[:format_error]}"
            puts "  Detail: #{error[:detail]}"
            puts "  Expected: #{error[:expected]}"
            puts "  Actual: #{error[:actual]}"
            puts "  → #{error[:fix_hint]}"
          else  # validator_id error
            puts "  validator_id: #{error[:validator_id] || 'NOT DEFINED'}"
            puts "  Expected: #{error[:expected]}"
            puts "  Issue: #{error[:issue]}"
            puts "  → Ensure validator_id matches filename format"
          end
        end
        puts "\n💡 Fix: Ensure validator_id matches filename and task_id is valid UUID"
      end
      
      if errors[:step2]&.any?
        puts "\n❌ Step 2: State Management Errors"
        puts "-" * 70
        errors[:step2].each do |error|
          puts "\n#{error[:validator]}"
          puts "  File: #{error[:file]}"
          puts "  Missing methods: #{error[:missing_methods].join(', ')}"
          puts "  Instance variables in prepare: #{error[:instance_vars].map { |v| '@' + v }.join(', ')}"
          puts "  → These variables will be nil during verify phase!"
        end
        puts "\n💡 Fix: Add execution_state_data and restore_from_state methods"
      end
      
      if errors[:step3]&.any?
        puts "\n❌ Step 3: State Save/Restore Field Mismatch"
        puts "-" * 70
        errors[:step3].first(5).each do |error|
          puts "\n#{error[:validator]}"
          puts "  File: #{error[:file]}"
          if error[:missing_in_restore].any?
            puts "  Missing in restore_from_state: #{error[:missing_in_restore].join(', ')}"
            puts "  → These fields are saved but NOT restored!"
          end
          if error[:extra_in_restore].any?
            puts "  Extra in restore_from_state: #{error[:extra_in_restore].join(', ')}"
            puts "  → These fields are restored but NOT saved!"
          end
        end
        if errors[:step3].size > 5
          puts "\n  ... and #{errors[:step3].size - 5} more validators with mismatched fields"
        end
        puts "\n💡 Fix: Ensure execution_state_data and restore_from_state have matching field names"
      end
      
      if errors[:step4]&.any?
        puts "\n❌ Step 4: Prepare Method Violations"
        puts "-" * 70
        errors[:step4].each do |error|
          puts "\n#{error[:validator]}"
          puts "  File: #{error[:file]}"
          puts "  违规操作:"
          error[:violations].each { |v| puts "    → #{v}" }
        end
        puts "\n💡 Fix: Use find_by! instead of find_or_create_by!"
      end
      
      if errors[:step5]&.any?
        puts "\n❌ Step 5: Simulate Method Data Creation Violations"
        puts "-" * 70
        errors[:step5].each do |error|
          puts "\n#{error[:validator]}"
          puts "  File: #{error[:file]}"
          puts "  违规操作:"
          error[:violations].each { |v| puts "    → #{v}" }
          if error[:code_samples]&.any?
            puts "  违规代码示例:"
            error[:code_samples].each do |sample|
              puts "    第#{sample[:line_num]}行: #{sample[:code]}"
            end
          end
        end
        puts "\n💡 Fix: Remove data_version: 0 creation in simulate"
      end
      
      if errors[:step6]&.any?
        puts "\n❌ Step 6: Weight Sum Errors"
        puts "-" * 70
        errors[:step6].each do |error|
          puts "\n#{error[:validator]}"
          puts "  Error: #{error[:error]}"
          puts "  Weights: #{error[:weights].inspect}" if error[:weights].any?
          puts "  Sum: #{error[:sum]}"
        end
        puts "\n💡 Fix: Adjust weights to sum to exactly 100"
      end
      
      puts "\n" + "="*70
    end
    
    private
    
    def check_validator_id_format(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        
        # Check validator_id
        validator_id_match = content.match(/self\.validator_id\s*=\s*['"]([^'"]+)['"]/)  
        validator_id = validator_id_match ? validator_id_match[1] : nil
        expected_id = validator_name
        
        if validator_id.nil?
          errors << { validator: validator_name, file: file, validator_id: nil, expected: expected_id, issue: 'validator_id not defined' }
        elsif validator_id != expected_id
          errors << { validator: validator_name, file: file, validator_id: validator_id, expected: expected_id, issue: 'validator_id does not match filename' }
        end
        
        # Check task_id UUID format
        task_id_match = content.match(/self\.task_id\s*=\s*['"]([^'"]+)['"]/)  
        if task_id_match
          task_id = task_id_match[1]
          
          # UUID format: 8-4-4-4-12 (e.g., 550e8400-e29b-41d4-a716-446655440000)
          uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
          
          unless task_id.match?(uuid_pattern)
            # Detect invalid characters (non-hex)
            invalid_chars = task_id.gsub('-', '').chars.select { |c| !c.match?(/[0-9a-f]/i) }.uniq
            
            error_detail = if invalid_chars.any?
              "包含非十六进制字符: #{invalid_chars.join(', ')}"
            else
              "格式不符合 UUID 标准（应为 8-4-4-4-12 格式）"
            end
            
            errors << {
              validator: validator_name,
              file: file,
              format_error: 'task_id 不符合标准 UUID 格式',
              detail: error_detail,
              expected: '标准 UUID 格式（仅包含 0-9, a-f 字符）',
              actual: "'#{task_id}'",
              fix_hint: 'task_id 必须符合标准 UUID 格式（8-4-4-4-12，仅包含 0-9, a-f 字符）。可使用 SecureRandom.uuid 生成标准 UUID'
            }
          end
        end
      end
      
      errors
    end
    
    def check_state_management(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        has_prepare = content.match?(/def\s+prepare/)
        prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
        has_execution_state_data = content.match?(/def\s+execution_state_data/)
        has_restore_from_state = content.match?(/def\s+restore_from_state/)
        
        if has_prepare && prepare_method
          instance_vars = prepare_method.scan(/@(\w+)\s*=/).flatten.uniq.reject { |v| v == 'data_version' }
          
          if instance_vars.any?
            if !has_execution_state_data || !has_restore_from_state
              missing_methods = []
              missing_methods << 'execution_state_data' unless has_execution_state_data
              missing_methods << 'restore_from_state' unless has_restore_from_state
              errors << { validator: validator_name, file: file, missing_methods: missing_methods, instance_vars: instance_vars }
            end
          end
        end
      end
      
      errors
    end
    
    def check_state_consistency(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        execution_state_data_method = content.match(/def\s+execution_state_data.*?\{(.*?)\}/m)&.[](1)
        restore_from_state_method = content.match(/def\s+restore_from_state\(data\)(.*?)(?:def |private|\z)/m)&.[](1)
        
        if execution_state_data_method && restore_from_state_method
          saved_keys = execution_state_data_method.scan(/(\w+):/).flatten.uniq
          restored_keys = restore_from_state_method.scan(/data\[(['"])(\w+)\1\]/).map { |m| m[1] }.uniq
          saved_set = Set.new(saved_keys)
          restored_set = Set.new(restored_keys)
          missing_in_restore = saved_set - restored_set
          extra_in_restore = restored_set - saved_set
          
          if missing_in_restore.any? || extra_in_restore.any?
            errors << { validator: validator_name, file: file, saved_keys: saved_keys, restored_keys: restored_keys, missing_in_restore: missing_in_restore.to_a, extra_in_restore: extra_in_restore.to_a }
          end
        end
      end
      
      errors
    end
    
    def check_prepare_violations(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        prepare_method = content.match(/def\s+prepare.*?^\s*end/m)&.[](0)
        
        if prepare_method
          violations = []
          violations << 'find_or_create_by!' if prepare_method.match?(/\.find_or_create_by[!]?\(/)
          violations << 'create/create!' if prepare_method.match?(/\.(create|create!)\(/)
          violations << 'Model.new + save' if prepare_method.match?(/\.new\([^)]*\)/) && prepare_method.match?(/\.save[!]?/)
          violations << 'update_all/delete_all/destroy_all' if prepare_method.match?(/\.(update_all|delete_all|destroy_all)\(/)
          violations << 'insert/insert_all' if prepare_method.match?(/\.(insert|insert_all)\(/)
          
          errors << { validator: validator_name, file: file, violations: violations } if violations.any?
        end
      end
      
      errors
    end
    
    def check_simulate_violations(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        simulate_method = content.match(/def\s+simulate.*?^\s*end/m)&.[](0)
        
        if simulate_method
          violations = []
          
          if simulate_method.match?(/\.create[!]?\([^)]*data_version:\s*0/m)
            creation_statements = simulate_method.scan(/(\w+)\.create[!]?\([^)]*data_version:\s*0[^)]*\)/m).flatten.uniq
            violations << "直接创建 data_version: 0 的记录: #{creation_statements.join(', ')}"
          end
          
          if simulate_method.match?(/@\w+\s*\|\|\s*\w+\.create[!]?\([^)]*data_version:\s*0/m)
            fallback_patterns = simulate_method.scan(/@(\w+)\s*\|\|\s*(\w+)\.create[!]?/m)
            pattern_str = fallback_patterns.map { |var, model| "@#{var} || #{model}.create" }.join(', ')
            violations << "使用后备创建模式绕过数据包: #{pattern_str}"
          end
          
          if simulate_method.match?(/\.(insert|insert_all)\([^)]*data_version:\s*0/m)
            violations << "使用 insert/insert_all 创建 data_version: 0 的记录"
          end
          
          if violations.any?
            violation_lines = []
            simulate_method.each_line.with_index do |line, idx|
              if line.match?(/data_version:\s*0/) && (line.match?(/\.create/) || line.match?(/\.insert/))
                violation_lines << { line_num: idx + 1, code: line.strip }
              end
            end
            errors << { validator: validator_name, file: file, violations: violations, code_samples: violation_lines.first(5) }
          end
        end
      end
      
      errors
    end
    
    def check_weight_sums(files)
      errors = []
      
      files.each do |file|
        validator_name = File.basename(file, '.rb')
        content = File.read(file)
        weights = content.scan(/weight:\s*(\d+)/).flatten.map(&:to_i)
        
        if weights.empty?
          errors << { validator: validator_name, error: '未找到任何 weight 定义', sum: 0, weights: [] }
        elsif weights.sum != 100
          errors << { validator: validator_name, error: "权重总和为 #{weights.sum}，应该为 100", sum: weights.sum, weights: weights }
        end
      end
      
      errors
    end
  end
end
