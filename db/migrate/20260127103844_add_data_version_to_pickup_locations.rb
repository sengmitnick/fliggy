class AddDataVersionToPickupLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :pickup_locations, :data_version, :integer, default: 0

  end
end
