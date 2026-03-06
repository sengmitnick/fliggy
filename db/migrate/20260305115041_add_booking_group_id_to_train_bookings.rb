class AddBookingGroupIdToTrainBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :train_bookings, :booking_group_id, :string

  end
end
