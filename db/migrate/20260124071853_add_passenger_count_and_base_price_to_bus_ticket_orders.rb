class AddPassengerCountAndBasePriceToBusTicketOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :bus_ticket_orders, :passenger_count, :integer, default: 1
    add_column :bus_ticket_orders, :base_price, :decimal

  end
end
