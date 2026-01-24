class CreateBusTicketPassengers < ActiveRecord::Migration[7.2]
  def change
    create_table :bus_ticket_passengers do |t|
      t.references :bus_ticket_order, null: false, foreign_key: true
      t.string :passenger_name, null: false
      t.string :passenger_id_number, null: false
      t.string :insurance_type


      t.timestamps
    end
  end
end
