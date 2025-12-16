class AddInsuranceToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :insurance_type, :string
    add_column :bookings, :insurance_price, :decimal

  end
end
