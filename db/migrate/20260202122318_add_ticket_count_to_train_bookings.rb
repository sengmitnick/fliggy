class AddTicketCountToTrainBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :train_bookings, :ticket_count, :integer, default: 1

  end
end
