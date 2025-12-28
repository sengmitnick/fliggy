class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.references :hotel
      t.string :name
      t.string :size
      t.string :bed_type
      t.decimal :price, default: 0
      t.decimal :original_price, default: 0
      t.text :amenities
      t.boolean :breakfast_included, default: false
      t.string :cancellation_policy


      t.timestamps
    end
  end
end
