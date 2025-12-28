class AddReturnOfferToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :return_offer_id, :integer

  end
end
