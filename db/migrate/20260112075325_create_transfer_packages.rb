class CreateTransferPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :transfer_packages do |t|
      t.string :name
      t.string :vehicle_category
      t.integer :seats
      t.integer :luggage
      t.integer :wait_time
      t.string :refund_policy
      t.decimal :price, default: 0
      t.decimal :original_price
      t.decimal :discount_amount, default: 0
      t.text :features
      t.string :provider
      t.integer :priority, default: 0
      t.boolean :is_active, default: true


      t.timestamps
    end
  end
end
