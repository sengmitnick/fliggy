# frozen_string_literal: true

namespace :validator do
  desc "Lint all validators"
  task lint: :environment do
    require_relative '../validator_linter'
    linter = ValidatorLinter.new
    issues = linter.lint_all
    linter.report(issues)
    
    config = YAML.load_file('config/validator_lint_rules.yml')
    strict_mode = config.dig('strict_mode') || {}
    
    if strict_mode['enabled'] && strict_mode['fail_on_high_severity']
      high_issues = issues.select { |i| i.severity == 'HIGH' }
      if high_issues.any?
        puts "\nLint failed: #{high_issues.size} HIGH severity issues found"
        exit 1
      end
    end
    
    exit 0 if issues.empty?
    exit 1
  end
  
  desc "Lint single validator"
  task :lint_single, [:validator_id] => :environment do |t, args|
    require_relative '../validator_linter'
    
    unless args[:validator_id]
      puts "Usage: rake validator:lint_single[v010]"
      exit 1
    end
    
    linter = ValidatorLinter.new
    issues = linter.lint_single(args[:validator_id])
    
    if issues.empty?
      puts "\n[PASS] #{args[:validator_id]} passed all lint checks"
      exit 0
    else
      linter.report(issues)
      exit 1
    end
  end
end
