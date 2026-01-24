class AddLocationToHotels < ActiveRecord::Migration[7.2]
  def change
    add_column :hotels, :latitude, :decimal, precision: 10, scale: 6
    add_column :hotels, :longitude, :decimal, precision: 10, scale: 6

  end
end
