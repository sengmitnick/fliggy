class AddRoundTripToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :trip_type, :string, default: 'one_way'
    add_column :bookings, :return_flight_id, :integer
    add_column :bookings, :return_date, :date
    add_index :bookings, :return_flight_id
  end
end
