# frozen_string_literal: true

# 强制启用所有业务表的 RLS 策略
#
# 背景：
# PostgreSQL 的 ENABLE ROW LEVEL SECURITY 只对非表所有者生效。
# 如果表所有者（travel01）可以绕过 RLS，导致多会话数据隔离失败。
#
# 解决方案：
# 使用 FORCE ROW LEVEL SECURITY 强制对所有用户（包括表所有者）执行 RLS。
#
# 这是多会话数据隔离功能的关键修复！
class ForceRlsOnAllTables < ActiveRecord::Migration[7.2]
  def up
    tables = get_business_tables

    puts "\n" + "=" * 80
    puts "正在强制启用所有业务表的 RLS 策略（FORCE ROW LEVEL SECURITY）..."
    puts "=" * 80

    tables.each do |table|
      begin
        # 强制启用 RLS（关键修复）
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
    tables = get_business_tables

    puts "\n" + "=" * 80
    puts "正在取消强制 RLS..."
    puts "=" * 80

    tables.each do |table|
      begin
        execute "ALTER TABLE #{table} NO FORCE ROW LEVEL SECURITY"
        puts "  ✓ #{table}"
      rescue => e
        puts "  ✗ #{table}: #{e.message}"
      end
    end

    puts "\n✓ 完成！共处理 #{tables.count} 个表"
    puts "=" * 80
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
