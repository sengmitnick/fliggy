class CreateCruiseProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_products do |t|
      t.references :cruise_sailing
      t.references :cabin_type
      t.string :merchant_name
      t.decimal :price_per_person, default: 0
      t.integer :occupancy_requirement, default: 2
      t.integer :stock, default: 0
      t.integer :sales_count, default: 0
      t.boolean :is_refundable, default: true
      t.boolean :requires_confirmation, default: false
      t.string :status, default: "on_sale"
      t.string :badge


      t.timestamps
    end
  end
end
