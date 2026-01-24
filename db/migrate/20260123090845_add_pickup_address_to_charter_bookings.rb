class AddPickupAddressToCharterBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :charter_bookings, :pickup_address, :text

  end
end
