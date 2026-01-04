class AddInsuranceToHotelBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_bookings, :insurance_type, :string
    add_column :hotel_bookings, :insurance_price, :decimal
    add_column :hotel_bookings, :locked_until, :datetime
  end
end
