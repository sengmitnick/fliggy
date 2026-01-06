class CreateTrainBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :train_bookings do |t|
      t.references :user
      t.references :train
      t.string :passenger_name
      t.string :passenger_id_number
      t.string :contact_phone
      t.string :seat_type
      t.string :carriage_number
      t.string :seat_number
      t.decimal :total_price
      t.string :insurance_type
      t.decimal :insurance_price
      t.string :status, default: "pending"
      t.boolean :accept_terms, default: false


      t.timestamps
    end
  end
end
