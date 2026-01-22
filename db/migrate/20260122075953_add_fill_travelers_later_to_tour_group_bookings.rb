class AddFillTravelersLaterToTourGroupBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :tour_group_bookings, :fill_travelers_later, :boolean, default: false

  end
end
