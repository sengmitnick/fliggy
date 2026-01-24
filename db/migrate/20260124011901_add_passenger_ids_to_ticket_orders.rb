class AddPassengerIdsToTicketOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :ticket_orders, :passenger_ids, :jsonb

  end
end
