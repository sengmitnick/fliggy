class CreateMembershipProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :membership_products do |t|
      t.string :name
      t.string :slug
      t.string :category, default: "popular"
      t.decimal :price_cash, default: 0
      t.integer :price_mileage, default: 0
      t.decimal :original_price
      t.integer :sales_count, default: 0
      t.integer :stock
      t.decimal :rating, default: 5.0
      t.text :description
      t.string :image_url
      t.string :region
      t.boolean :featured, default: false

      t.timestamps
    end
    
    add_index :membership_products, :slug, unique: true
    add_index :membership_products, :category
    add_index :membership_products, :featured
  end
end
