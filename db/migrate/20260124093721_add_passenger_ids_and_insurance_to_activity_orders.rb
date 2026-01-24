class AddPassengerIdsAndInsuranceToActivityOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :activity_orders, :passenger_ids, :jsonb, default: []
    add_column :activity_orders, :insurance_type, :string, default: 'none'
  end
end
