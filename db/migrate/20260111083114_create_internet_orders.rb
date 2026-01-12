class CreateInternetOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :internet_orders do |t|
      t.references :user
      t.references :orderable
      t.string :order_type
      t.string :region
      t.integer :quantity, default: 1
      t.decimal :total_price
      t.string :status, default: "pending"
      t.string :delivery_method
      t.jsonb :delivery_info
      t.jsonb :contact_info
      t.jsonb :rental_info
      t.string :order_number


      t.timestamps
    end
  end
end
