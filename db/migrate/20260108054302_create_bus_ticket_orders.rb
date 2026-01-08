class CreateBusTicketOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :bus_ticket_orders do |t|
      t.references :user
      t.references :bus_ticket
      t.string :passenger_name
      t.string :passenger_id_number
      t.string :contact_phone
      t.string :departure_station
      t.string :arrival_station
      t.string :insurance_type
      t.decimal :insurance_price
      t.decimal :total_price
      t.string :status, default: "pending"


      t.timestamps
    end
  end
end
