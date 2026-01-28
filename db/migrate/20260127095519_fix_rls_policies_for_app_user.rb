# frozen_string_literal: true

class FixRlsPoliciesForAppUser < ActiveRecord::Migration[7.2]
  def up
    # 获取所有使用 public role 的 RLS 策略
    policies = execute(<<~SQL).to_a
      SELECT tablename, policyname 
      FROM pg_policies 
      WHERE schemaname = 'public' AND roles = '{public}'
    SQL
    
    puts "Found #{policies.size} RLS policies to update"
    
    policies.each do |policy|
      table = policy['tablename']
      policy_name = policy['policyname']
      
      # 获取策略的 qual 表达式
      qual_result = execute(<<~SQL).first
        SELECT pg_get_expr(polqual, polrelid) AS qual 
        FROM pg_policy 
        JOIN pg_class ON pg_policy.polrelid = pg_class.oid
        WHERE polname = '#{policy_name}' AND relname = '#{table}'
      SQL
      
      qual = qual_result['qual']
      
      # 重建策略：DROP 旧的，CREATE 新的
      execute("DROP POLICY #{policy_name} ON #{table}")
      execute(<<~SQL)
        CREATE POLICY #{policy_name} ON #{table}
        FOR ALL TO app_user
        USING (#{qual})
      SQL
      
      puts "✓ Updated #{table}.#{policy_name}"
    end
    
    puts "✅ All RLS policies updated successfully"
  end
  
  def down
    # 回滚不需要特别处理
  end
end
