# frozen_string_literal: true

# 修复 RLS 策略的 WITH CHECK 条件
#
# 问题：原始策略的 WITH CHECK 不允许 data_version = 0，导致无法插入基线数据
# 修复：WITH CHECK 条件也允许 data_version = 0
class FixRlsPoliciesWithCheck < ActiveRecord::Migration[7.2]
  def up
    tables = get_business_tables

    puts "\n" + "=" * 80
    puts "修复 RLS 策略的 WITH CHECK 条件..."
    puts "=" * 80

    tables.each do |table|
      begin
        policy_name = "#{table}_version_policy"

        # 删除旧策略
        execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"

        # 创建新策略（USING 和 WITH CHECK 都允许 data_version = 0）
        execute <<-SQL
          CREATE POLICY #{policy_name} ON #{table}
          FOR ALL TO app_user
          USING (
            data_version = 0
            OR data_version::text = current_setting('app.data_version', true)
          )
          WITH CHECK (
            data_version = 0
            OR data_version::text = current_setting('app.data_version', true)
          )
        SQL

        # 启用并强制 RLS
        execute "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY"
        execute "ALTER TABLE #{table} FORCE ROW LEVEL SECURITY"

        puts "  ✓ #{table}"
      rescue => e
        puts "  ✗ #{table}: #{e.message}"
      end
    end

    puts "\n✓ 完成！共处理 #{tables.count} 个表"
    puts "=" * 80
  end

  def down
    # 不需要回滚，保持 RLS 启用
  end

  private

  def get_business_tables
    # 排除的系统表
    excluded_tables = %w[
      schema_migrations
      ar_internal_metadata
      active_storage_blobs
      active_storage_attachments
      active_storage_variant_records
      good_jobs
      good_job_batches
      good_job_executions
      good_job_processes
      good_job_settings
      solid_cable_messages
      administrators
      sessions
      admin_oplogs
      validator_executions
      friendly_id_slugs
    ]

    # 获取所有表
    all_tables = ActiveRecord::Base.connection.tables

    # 过滤掉系统表
    business_tables = all_tables - excluded_tables

    # 只返回有 data_version 列的表（避免处理尚未添加该列的表）
    business_tables.select do |table|
      column_exists?(table, :data_version)
    end.sort
  end
end
