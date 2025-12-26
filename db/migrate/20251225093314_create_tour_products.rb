class CreateTourProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_products do |t|
      t.references :destination
      t.string :name
      t.string :product_type, default: "attraction"
      t.string :category, default: "local"
      t.decimal :price, default: 0
      t.decimal :original_price, default: 0
      t.integer :sales_count, default: 0
      t.decimal :rating, default: 5.0
      t.text :tags
      t.text :description
      t.string :image_url
      t.integer :rank, default: 0
      t.boolean :is_featured, default: false


      t.timestamps
    end
  end
end
