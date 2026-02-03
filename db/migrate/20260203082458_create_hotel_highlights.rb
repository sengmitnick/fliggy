class CreateHotelHighlights < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_highlights do |t|
      t.references :hotel
      t.string :title
      t.text :description
      t.string :icon
      t.integer :display_order, default: 0
      t.string :data_version, default: "'0'"


      t.timestamps
    end
  end
end
