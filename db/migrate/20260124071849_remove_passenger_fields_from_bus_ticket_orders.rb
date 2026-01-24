class RemovePassengerFieldsFromBusTicketOrders < ActiveRecord::Migration[7.2]
  def change
    remove_column :bus_ticket_orders, :passenger_name, :string
    remove_column :bus_ticket_orders, :passenger_id_number, :string
    remove_column :bus_ticket_orders, :contact_phone, :string
  end
end
