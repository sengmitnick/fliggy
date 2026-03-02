class AddBookingGroupIdToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :booking_group_id, :string

    add_index :bookings, :booking_group_id
  end
end
