class AddPassengerCountAndLuggageCountToTransfers < ActiveRecord::Migration[7.2]
  def change
    add_column :transfers, :passenger_count, :integer
    add_column :transfers, :luggage_count, :integer

  end
end
