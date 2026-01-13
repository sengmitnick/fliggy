class CreateVisaOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :visa_orders do |t|
      t.integer :user_id
      t.integer :visa_product_id
      t.integer :traveler_count, default: 1
      t.decimal :total_price, default: 0
      t.decimal :unit_price, default: 0
      t.string :status, default: "pending"
      t.date :expected_date
      t.string :delivery_method, default: "express"
      t.text :delivery_address
      t.string :contact_name
      t.string :contact_phone
      t.text :notes
      t.boolean :insurance_selected, default: false
      t.decimal :insurance_price, default: 0
      t.string :payment_status, default: "unpaid"
      t.datetime :paid_at
      t.string :slug


      t.timestamps
    end
  end
end
