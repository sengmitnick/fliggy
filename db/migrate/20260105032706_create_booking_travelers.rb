class CreateBookingTravelers < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_travelers do |t|
      t.integer :tour_group_booking_id
      t.string :traveler_name
      t.string :id_number
      t.string :traveler_type, default: "adult"

      t.index :tour_group_booking_id

      t.timestamps
    end
  end
end
