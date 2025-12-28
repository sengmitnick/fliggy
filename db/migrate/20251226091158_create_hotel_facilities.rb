class CreateHotelFacilities < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_facilities do |t|
      t.references :hotel
      t.string :name
      t.string :icon
      t.string :description
      t.string :category


      t.timestamps
    end
  end
end
