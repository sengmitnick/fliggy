class CreateMembershipOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :membership_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :membership_product, null: false, foreign_key: true
      t.string :order_number, null: false
      t.integer :quantity, default: 1, null: false
      t.decimal :price_cash, precision: 10, scale: 2, default: 0
      t.decimal :price_mileage, precision: 10, scale: 2, default: 0
      t.decimal :total_cash, precision: 10, scale: 2, default: 0
      t.decimal :total_mileage, precision: 10, scale: 2, default: 0
      t.string :contact_name
      t.string :contact_phone
      t.text :shipping_address
      t.string :status, default: 'pending'
      t.string :data_version, limit: 50, default: '0', null: false

      t.timestamps
    end

    add_index :membership_orders, :order_number, unique: true
    add_index :membership_orders, :status
    add_index :membership_orders, :data_version
  end
end
