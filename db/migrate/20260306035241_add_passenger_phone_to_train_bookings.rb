class AddPassengerPhoneToTrainBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :train_bookings, :passenger_phone, :string

  end
end
