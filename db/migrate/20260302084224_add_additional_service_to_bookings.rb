class AddAdditionalServiceToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :additional_service_type, :string
    add_column :bookings, :additional_service_price, :decimal

  end
end
