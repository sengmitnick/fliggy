class CreateTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :transfers do |t|
      t.references :user
      t.string :transfer_type, default: "airport_pickup"
      t.string :service_type, default: "to_airport"
      t.string :location_from
      t.string :location_to
      t.datetime :pickup_datetime
      t.string :flight_number
      t.string :train_number
      t.string :passenger_name
      t.string :passenger_phone
      t.string :vehicle_type, default: "economy_5"
      t.string :provider_name
      t.string :license_plate
      t.string :driver_name
      t.string :driver_status, default: "pending"
      t.decimal :total_price, default: 0
      t.decimal :discount_amount, default: 0
      t.string :status, default: "pending"


      t.timestamps
    end
  end
end
