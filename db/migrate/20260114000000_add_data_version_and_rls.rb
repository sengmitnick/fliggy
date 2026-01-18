# frozen_string_literal: true

class AddDataVersionAndRls < ActiveRecord::Migration[7.2]
  def up
    # \u83b7\u53d6\u6240\u6709\u4e1a\u52a1\u8868\uff08\u6392\u9664\u7cfb\u7edf\u8868\uff09
    tables = get_business_tables
    
    puts "\n" + "=" * 80
    puts "\u6b63\u5728\u6dfb\u52a0 data_version \u5217\u5e76\u542f\u7528 RLS \u7b56\u7565..."
    puts "=" * 80
    
    tables.each do |table|
      puts "  \u2192 \u5904\u7406\u8868: #{table}"
      
      # 1. \u6dfb\u52a0 data_version \u5217
      add_column table, :data_version, :integer, default: 0, null: false unless column_exists?(table, :data_version)
      add_index table, :data_version unless index_exists?(table, :data_version)
      
      # 2. \u542f\u7528 RLS
      execute "ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY"
      
      # 3. \u521b\u5efa RLS \u7b56\u7565
      policy_name = "#{table}_version_policy"
      
      # \u5148\u5220\u9664\u5df2\u5b58\u5728\u7684\u7b56\u7565\uff08\u5982\u679c\u6709\uff09
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"
      
      # \u521b\u5efa\u65b0\u7b56\u7565
      execute <<-SQL
        CREATE POLICY #{policy_name} ON #{table}
        FOR ALL
        USING (
          data_version = 0 
          OR data_version::text = current_setting('app.data_version', true)
        )
        WITH CHECK (
          data_version::text = current_setting('app.data_version', true)
        )
      SQL
    end
    
    puts "\u2713 \u5b8c\u6210\uff01\u5171\u5904\u7406 #{tables.count} \u4e2a\u8868"
  end
  
  def down
    tables = get_business_tables
    
    puts "\n" + "=" * 80
    puts "\u6b63\u5728\u79fb\u9664 data_version \u5217\u548c RLS \u7b56\u7565..."
    puts "=" * 80
    
    tables.each do |table|
      puts "  \u2192 \u5904\u7406\u8868: #{table}"
      
      # 1. \u5220\u9664 RLS \u7b56\u7565
      policy_name = "#{table}_version_policy"
      execute "DROP POLICY IF EXISTS #{policy_name} ON #{table}"
      
      # 2. \u7981\u7528 RLS
      execute "ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY"
      
      # 3. \u79fb\u9664 data_version \u5217
      remove_column table, :data_version if column_exists?(table, :data_version)
    end
    
    puts "\u2713 \u5b8c\u6210\uff01\u5171\u5904\u7406 #{tables.count} \u4e2a\u8868"
  end
  
  private
  
  def get_business_tables
    # \u6392\u9664\u7684\u7cfb\u7edf\u8868
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
    
    # \u83b7\u53d6\u6240\u6709\u8868
    all_tables = ActiveRecord::Base.connection.tables
    
    # \u8fc7\u6ee4\u6389\u7cfb\u7edf\u8868
    business_tables = all_tables - excluded_tables
    
    business_tables.sort
  end
end
