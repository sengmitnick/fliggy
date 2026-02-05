class AddVehicleModelToTransferPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :transfer_packages, :vehicle_model, :string
    add_column :transfer_packages, :vehicle_brand, :string

  end
end
