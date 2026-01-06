class CreateHotelPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_packages do |t|
      t.string :brand_name
      t.string :title
      t.text :description
      t.decimal :price
      t.decimal :original_price
      t.integer :sales_count, default: 0
      t.boolean :is_featured, default: false
      t.integer :valid_days, default: 365
      t.text :terms
      t.string :brand_logo_url
      t.string :region
      t.string :package_type, default: "standard"
      t.integer :display_order, default: 0

      t.index :brand_name

      t.timestamps
    end
  end
end
