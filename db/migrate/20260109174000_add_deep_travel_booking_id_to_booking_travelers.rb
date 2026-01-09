class AddDeepTravelBookingIdToBookingTravelers < ActiveRecord::Migration[7.2]
  def change
    add_column :booking_travelers, :deep_travel_booking_id, :integer
    add_index :booking_travelers, :deep_travel_booking_id
  end
end
