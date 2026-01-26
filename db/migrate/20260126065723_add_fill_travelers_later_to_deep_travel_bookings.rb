class AddFillTravelersLaterToDeepTravelBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :deep_travel_bookings, :fill_travelers_later, :boolean, default: false
  end
end
