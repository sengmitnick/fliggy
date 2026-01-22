class CreateCruiseOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_orders do |t|
      t.references :user
      t.references :cruise_product
      t.integer :quantity, default: 1
      t.decimal :total_price, default: 0
      t.jsonb :passenger_info
      t.string :contact_name
      t.string :contact_phone
      t.string :insurance_type
      t.decimal :insurance_price, default: 0
      t.string :status, default: "pending"
      t.string :order_number
      t.boolean :accept_terms, default: false


      t.timestamps
    end
  end
end
