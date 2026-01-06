class CreatePackageOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :package_options do |t|
      t.references :hotel_package
      t.string :name
      t.decimal :price
      t.decimal :original_price
      t.integer :night_count
      t.text :description
      t.boolean :can_split, default: true
      t.integer :display_order, default: 0
      t.boolean :is_active, default: true


      t.timestamps
    end
  end
end
