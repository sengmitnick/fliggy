class RemoveActiveStorageTables < ActiveRecord::Migration[7.2]
  def up
    # 删除 ActiveStorage 相关表
    drop_table :active_storage_variant_records if table_exists?(:active_storage_variant_records)
    drop_table :active_storage_attachments if table_exists?(:active_storage_attachments)
    drop_table :active_storage_blobs if table_exists?(:active_storage_blobs)
  end

  def down
    # 不可逆 - 如果需要恢复，重新运行 rails active_storage:install
    raise ActiveRecord::IrreversibleMigration
  end
end
