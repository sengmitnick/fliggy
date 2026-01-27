# frozen_string_literal: true

# 为缺少 data_version 列的业务表补全该列
#
# 背景：
# 初始的 RLS 迁移（20260114000000）只为当时存在的表添加了 data_version。
# 后续新建的表缺少该列，导致 RLS 策略无法应用。
#
# 解决方案：
# 为所有缺少 data_version 的业务表添加该列，并启用 RLS 策略。
class AddDataVersionToMissingTables < ActiveRecord::Migration[7.2]
  def up
    tables = get_tables_without_data_version
    
    if tables.empty?
      puts "\n✓ 所有业务表都已有 data_version 列，无需处理"
      return
    end

    puts "\n" + "=" * 80
    puts "为缺少 data_version 的业务表补全该列..."
    puts "=" * 80
    puts "发现 #{tables.count} 个表需要处理："
    tables.each { |t| puts "  - #{t}" }
    puts ""

    tables.each do |table|
      puts "  → 处理表: #{table}"
      
      # 1. 添加 data_version 列
      add_column table, :data_version, :integer, default: 0, null: false
      add_index table, :data_version
      
      # 2. 启用 RLS
      execute "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY"
      execute "ALTER TABLE #{table} FORCE ROW LEVEL SECURITY"
      
      # 3. 创建 RLS 策略
      policy_name = "#{table}_version_policy"
      
      # 先删除已存在的策略（如果有）
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"
      
      # 创建新策略
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
      
      puts "    ✓ 已添加 data_version 列并启用 RLS"
    end

    puts "\n✓ 完成！共处理 #{tables.count} 个表"
    puts "=" * 80
  end

  def down
    tables = get_all_business_tables.select { |t| column_exists?(t, :data_version) }
    
    puts "\n" + "=" * 80
    puts "回滚：仅移除本次迁移添加的 data_version 列..."
    puts "=" * 80

    # 注意：这里不会真正回滚，因为我们无法区分哪些列是本次添加的
    # 如需回滚，请手动执行
    puts "⚠️  警告：自动回滚已禁用，请手动检查并回滚"
    puts "=" * 80
  end

  private

  def get_tables_without_data_version
    all_tables = get_all_business_tables
    
    all_tables.select do |table|
      !column_exists?(table, :data_version)
    end
  end

  def get_all_business_tables
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

    business_tables.sort
  end
end
