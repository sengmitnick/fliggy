class CreateHotelNearbyPlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_nearby_places do |t|
      t.references :hotel
      t.string :place_type
      t.string :name
      t.string :distance
      t.text :description
      t.integer :display_order, default: 0
      t.string :data_version, default: "'0'"


      t.timestamps
    end
  end
end
