class CreateMembershipOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :membership_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :membership_product, null: false, foreign_key: true
      t.integer :quantity, default: 1
      t.decimal :price_cash, default: 0
      t.integer :price_mileage, default: 0
      t.decimal :total_cash, default: 0
      t.integer :total_mileage, default: 0
      t.string :status, default: "pending"
      t.string :order_number
      t.text :shipping_address
      t.string :contact_phone
      t.string :contact_name
      t.text :notes

      t.timestamps
    end
    
    add_index :membership_orders, :order_number, unique: true
    add_index :membership_orders, :status
  end
end
