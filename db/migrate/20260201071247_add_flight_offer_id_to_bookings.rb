class AddFlightOfferIdToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :flight_offer_id, :bigint

  end
end
