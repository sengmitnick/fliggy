class AddBookingOptionToTrainBookings < ActiveRecord::Migration[7.2]
  def change
    add_reference :train_bookings, :booking_option, null: true, foreign_key: true
  end
end
