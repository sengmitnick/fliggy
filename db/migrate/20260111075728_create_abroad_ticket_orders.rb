class CreateAbroadTicketOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :abroad_ticket_orders do |t|
      t.references :user
      t.references :abroad_ticket
      t.string :passenger_name
      t.string :passenger_id_number
      t.string :contact_phone
      t.string :contact_email
      t.string :passenger_type, default: "1adult"
      t.string :seat_category, default: "自由席"
      t.decimal :total_price, default: 0
      t.string :status, default: "pending"
      t.text :notes


      t.timestamps
    end
  end
end
