class CreateCabinTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :cabin_types do |t|
      t.references :cruise_ship
      t.string :name
      t.string :category
      t.string :floor_range
      t.decimal :area, default: 0
      t.boolean :has_balcony, default: false
      t.boolean :has_window, default: false
      t.integer :max_occupancy, default: 2
      t.text :description
      t.jsonb :image_urls


      t.timestamps
    end
  end
end
