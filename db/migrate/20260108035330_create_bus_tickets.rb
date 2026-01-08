class CreateBusTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :bus_tickets do |t|
      t.string :origin
      t.string :destination
      t.date :departure_date
      t.string :departure_time
      t.string :arrival_time
      t.decimal :price, default: 0
      t.string :status, default: "available"
      t.string :seat_type


      t.timestamps
    end
  end
end
