class AddMultiCityFieldsToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :multi_city_flights, :jsonb

  end
end
