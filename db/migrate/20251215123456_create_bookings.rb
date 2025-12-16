class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :user
      t.references :flight
      t.string :passenger_name
      t.string :passenger_id_number
      t.string :contact_phone
      t.decimal :total_price
      t.string :status, default: "pending"
      t.boolean :accept_terms, default: false


      t.timestamps
    end
  end
end
