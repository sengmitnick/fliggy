class AddContactInfoToInsuranceOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :insurance_orders, :contact_name, :string
    add_column :insurance_orders, :contact_phone, :string
    add_column :insurance_orders, :contact_email, :string

  end
end
