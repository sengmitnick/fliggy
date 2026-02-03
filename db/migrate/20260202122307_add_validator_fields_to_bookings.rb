class AddValidatorFieldsToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :seat_preference, :string
    add_column :bookings, :seat_number, :string
    add_column :bookings, :frequent_flyer_number, :string

  end
end
