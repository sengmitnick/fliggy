class CreateHotelPackageOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_package_orders do |t|
      t.references :hotel_package
      t.references :user
      t.string :order_number
      t.integer :quantity, default: 1
      t.decimal :total_price
      t.string :status, default: "pending"
      t.string :payment_method
      t.datetime :purchased_at
      t.integer :used_count, default: 0
      t.datetime :valid_until

      t.index :order_number

      t.timestamps
    end
  end
end
