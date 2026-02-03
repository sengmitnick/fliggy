class AddRoomCountToHotelBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_bookings, :room_count, :integer, default: 1

  end
end
