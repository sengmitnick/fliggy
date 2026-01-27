# frozen_string_literal: true

# 将所有表的 data_version 从 integer/bigint 转换为 string
#
# 背景：
# - data_version 用于 RLS 策略中与 PostgreSQL session 变量比较
# - Session 变量是字符串类型，使用 integer/bigint 需要频繁类型转换（::text）
# - 这导致性能开销和代码复杂度增加
#
# 改进：
# 1. 使用 string 类型直接匹配 session 变量，无需类型转换
# 2. 支持更灵活的版本标识（UUID、语义化标识等）
# 3. 简化 RLS 策略 SQL，提高查询性能
#
# 注意：
# - 此迁移会修改所有已有 data_version 列的类型
# - 数据会自动转换：0 -> '0'
# - RLS 策略会被重新创建以使用新的类型
#
class ConvertAllDataVersionToString < ActiveRecord::Migration[7.2]
  def up
    tables = get_tables_with_data_version

    if tables.empty?
      puts "\n✓ 没有找到需要转换的表"
      return
    end

    puts "\n" + "=" * 80
    puts "将所有表的 data_version 从 integer/bigint 转换为 string..."
    puts "=" * 80
    puts "发现 #{tables.count} 个表需要处理"
    puts ""

    # 抑制 ActiveRecord 的详细迁移日志
    old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false

    tables.each do |table|
      print "  → 处理表: #{table.ljust(40)}"

      begin
        # 检查当前列类型
        column = connection.columns(table).find { |c| c.name == 'data_version' }
        current_type = column.sql_type

        # 如果已经是 string/varchar，跳过
        if current_type.start_with?('character varying', 'varchar', 'text')
          puts "    ⊙ 已经是 string 类型，跳过"
          next
        end

        policy_name = "#{table}_version_policy"

        # 1. 删除现有的 RLS 策略
        execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"

        # 2. 转换列类型
        # PostgreSQL 会自动将 integer/bigint 转换为 text (0 -> '0')
        change_column table, :data_version, :string, limit: 50, default: '0', null: false

        # 3. 重新创建 RLS 策略（使用 string 类型，无需 ::text 转换）
        execute <<-SQL
          CREATE POLICY #{policy_name} ON #{table}
          FOR ALL TO app_user
          USING (
            data_version = '0'
            OR data_version = current_setting('app.data_version', true)
          )
          WITH CHECK (
            data_version = '0'
            OR data_version = current_setting('app.data_version', true)
          )
        SQL

        puts " ✓"
      rescue StandardError => e
        puts " ✗"
        puts "    错误: #{e.message}"
        # 继续处理下一个表，不中断整个迁移
      end
    end

    # 恢复原始设置
    ActiveRecord::Migration.verbose = old_verbose

    puts "\n✓ 完成！共处理 #{tables.count} 个表"
    puts "=" * 80
  end

  def down
    puts "\n" + "=" * 80
    puts "回滚: 将 data_version 从 string 转回 integer"
    puts "=" * 80
    puts ""

    tables = get_tables_with_data_version

    tables.each do |table|
      puts "  → 回滚表: #{table}"

      begin
        policy_name = "#{table}_version_policy"

        # 1. 删除 RLS 策略
        execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"

        # 2. 将 string 转回 integer
        # 注意: 这假设所有值都是数字字符串
        change_column table, :data_version, :integer, default: 0, null: false

        # 3. 重新创建原始的 RLS 策略（带 ::text 转换）
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

        puts "    ✓ 已回滚"
      rescue StandardError => e
        puts "    ✗ 回滚失败: #{e.message}"
      end
    end

    puts "\n✓ 回滚完成"
    puts "=" * 80
  end

  private

  def get_tables_with_data_version
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
    all_tables = connection.tables

    # 过滤掉系统表并返回有 data_version 列的表
    (all_tables - excluded_tables).select do |table|
      column_exists?(table, :data_version)
    end.sort
  end
end
