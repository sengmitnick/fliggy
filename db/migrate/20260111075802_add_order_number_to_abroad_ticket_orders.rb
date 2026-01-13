class AddOrderNumberToAbroadTicketOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :abroad_ticket_orders, :order_number, :string

  end
end
