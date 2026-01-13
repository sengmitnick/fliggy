class AddTransferPackageIdToTransfers < ActiveRecord::Migration[7.2]
  def change
    add_column :transfers, :transfer_package_id, :integer
    add_index :transfers, :transfer_package_id
    add_foreign_key :transfers, :transfer_packages
  end
end
