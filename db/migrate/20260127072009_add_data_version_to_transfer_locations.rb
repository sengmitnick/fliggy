class AddDataVersionToTransferLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :transfer_locations, :data_version, :bigint, default: 0, null: false
    add_index :transfer_locations, :data_version
    
    # 启用 RLS
    execute "ALTER TABLE transfer_locations ENABLE ROW LEVEL SECURITY"
    
    # 创建 RLS 策略
    execute <<-SQL
      CREATE POLICY transfer_locations_version_policy ON transfer_locations
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
end
