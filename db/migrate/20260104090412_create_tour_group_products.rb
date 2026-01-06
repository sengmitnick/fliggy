class CreateTourGroupProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_group_products do |t|
      t.string :title
      t.string :subtitle
      t.string :tour_category, default: "group_tour"
      t.string :destination
      t.integer :duration, default: 1
      t.string :departure_city
      t.decimal :price, default: 0
      t.decimal :original_price, default: 0
      t.decimal :rating, default: 0
      t.string :rating_desc
      t.text :highlights
      t.text :tags
      t.string :provider
      t.integer :sales_count, default: 0
      t.string :badge
      t.string :departure_label
      t.string :image_url
      t.boolean :is_featured, default: false
      t.integer :display_order, default: 0


      t.timestamps
    end
  end
end
