class AddInsuranceTypeToVisaOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :visa_orders, :insurance_type, :string

  end
end
