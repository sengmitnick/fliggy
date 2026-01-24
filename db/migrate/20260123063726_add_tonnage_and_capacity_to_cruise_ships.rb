class AddTonnageAndCapacityToCruiseShips < ActiveRecord::Migration[7.2]
  def change
    add_column :cruise_ships, :tonnage, :integer
    add_column :cruise_ships, :passenger_capacity, :integer

  end
end
