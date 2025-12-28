class CreateHotels < ActiveRecord::Migration[7.2]
  def change
    create_table :hotels do |t|
      t.string :name
      t.string :city, default: "深圳市"
      t.text :address
      t.decimal :rating, default: 4.5
      t.decimal :price
      t.decimal :original_price
      t.string :distance
      t.text :features
      t.integer :star_level, default: 4
      t.string :image_url
      t.boolean :is_featured, default: false
      t.integer :display_order, default: 0


      t.timestamps
    end
  end
end
