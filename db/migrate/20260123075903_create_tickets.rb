class CreateTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :tickets do |t|
      t.references :attraction
      t.string :name
      t.string :ticket_type, default: "adult"
      t.decimal :original_price
      t.decimal :current_price
      t.string :discount_info
      t.text :requirements
      t.string :refund_policy
      t.text :booking_notice
      t.integer :validity_days
      t.integer :sales_count, default: 0
      t.integer :stock, default: -1


      t.timestamps
    end
  end
end
