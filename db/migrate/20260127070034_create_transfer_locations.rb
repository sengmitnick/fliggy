class CreateTransferLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :transfer_locations do |t|
      t.string :city
      t.string :name
      t.string :location_type, default: "airport"
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      t.timestamps
    end
    
    add_index :transfer_locations, :city
    add_index :transfer_locations, :location_type
  end
end
