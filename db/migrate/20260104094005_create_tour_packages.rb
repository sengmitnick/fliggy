class CreateTourPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_packages do |t|
      t.references :tour_group_product
      t.string :name
      t.decimal :price, default: 0
      t.decimal :child_price, default: 0
      t.integer :purchase_count, default: 0
      t.text :description
      t.boolean :is_featured, default: false
      t.integer :display_order, default: 0


      t.timestamps
    end
  end
end
