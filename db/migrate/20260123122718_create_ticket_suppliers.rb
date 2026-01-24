class CreateTicketSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_suppliers do |t|
      t.integer :ticket_id
      t.integer :supplier_id
      t.decimal :current_price
      t.decimal :original_price
      t.integer :stock, default: -1
      t.string :discount_info
      t.integer :sales_count, default: 0
      t.integer :data_version, default: 0


      t.timestamps
    end
  end
end
