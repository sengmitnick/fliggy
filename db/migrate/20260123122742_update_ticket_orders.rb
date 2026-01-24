class UpdateTicketOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :ticket_orders, :supplier_id, :integer
    add_column :ticket_orders, :traveler_id, :integer
    remove_column :ticket_orders, :passenger_name, :string
    remove_column :ticket_orders, :passenger_id_number, :string
  end
end
