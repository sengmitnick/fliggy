class CreateMembershipProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :membership_products do |t|
      t.string :name, null: false
      t.string :slug
      t.string :category, default: 'popular'
      t.decimal :price_cash, precision: 10, scale: 2, default: 0
      t.integer :price_mileage, default: 0
      t.decimal :original_price, precision: 10, scale: 2
      t.integer :sales_count, default: 0
      t.integer :stock
      t.decimal :rating, precision: 3, scale: 2, default: 0
      t.text :description
      t.string :image_url
      t.string :region, default: 'domestic'
      t.boolean :featured, default: false
      t.string :data_version, limit: 50, default: '0', null: false

      t.timestamps
    end

    add_index :membership_products, :slug, unique: true
    add_index :membership_products, :category
    add_index :membership_products, :region
    add_index :membership_products, :featured
    add_index :membership_products, :data_version
  end
end
