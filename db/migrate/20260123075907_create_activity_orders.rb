class CreateActivityOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :activity_orders do |t|
      t.references :user
      t.references :attraction_activity
      t.string :passenger_name
      t.string :contact_phone
      t.date :visit_date
      t.integer :quantity, default: 1
      t.decimal :total_price
      t.string :status, default: "pending"
      t.string :order_number


      t.timestamps
    end
  end
end
