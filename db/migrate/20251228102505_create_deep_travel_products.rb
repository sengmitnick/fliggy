class CreateDeepTravelProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :deep_travel_products do |t|
      t.string :title
      t.string :subtitle
      t.string :location
      t.references :deep_travel_guide, foreign_key: true
      t.decimal :price, precision: 10, scale: 2
      t.integer :sales_count, default: 0
      t.text :description
      t.text :itinerary
      t.boolean :featured, default: false


      t.timestamps
    end
  end
end
