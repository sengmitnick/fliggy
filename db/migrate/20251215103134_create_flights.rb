class CreateFlights < ActiveRecord::Migration[7.2]
  def change
    create_table :flights do |t|
      t.string :departure_city
      t.string :destination_city
      t.datetime :departure_time
      t.datetime :arrival_time
      t.string :departure_airport
      t.string :arrival_airport
      t.string :airline
      t.string :flight_number
      t.string :aircraft_type
      t.decimal :price
      t.decimal :discount_price, default: 0
      t.string :seat_class, default: "economy"
      t.integer :available_seats, default: 100
      t.date :flight_date


      t.timestamps
    end
  end
end
