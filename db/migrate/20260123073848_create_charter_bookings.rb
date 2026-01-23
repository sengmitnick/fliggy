class CreateCharterBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :charter_bookings do |t|
      t.integer :user_id
      t.integer :charter_route_id
      t.integer :vehicle_type_id
      t.date :departure_date
      t.string :departure_time
      t.integer :duration_hours, default: 6
      t.string :booking_mode, default: "by_route"
      t.string :contact_name
      t.string :contact_phone
      t.integer :passengers_count, default: 1
      t.text :note
      t.decimal :total_price
      t.string :status, default: "pending"
      t.string :order_number
      t.datetime :paid_at


      t.timestamps
    end
  end
end
