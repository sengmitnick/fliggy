class AddValidatorFieldsToFlights < ActiveRecord::Migration[7.2]
  def change
    add_column :flights, :baggage_allowance, :string
    add_column :flights, :refund_policy, :string
    add_column :flights, :meal_service, :string
    add_column :flights, :mileage_accrual, :string
    add_column :flights, :is_direct, :boolean, default: true
    add_column :flights, :stops, :integer, default: 0

  end
end
