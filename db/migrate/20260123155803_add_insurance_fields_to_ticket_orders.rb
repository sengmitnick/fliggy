class AddInsuranceFieldsToTicketOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :ticket_orders, :insurance_type, :string
    add_column :ticket_orders, :insurance_price, :integer
    add_column :ticket_orders, :total_amount, :decimal
    add_column :ticket_orders, :notes, :text

  end
end
