class AddTravelTypeToTourGroupProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :tour_group_products, :travel_type, :string

  end
end
