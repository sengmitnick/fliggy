class AddStationFieldsToTrains < ActiveRecord::Migration[7.2]
  def change
    add_column :trains, :departure_station, :string
    add_column :trains, :arrival_station, :string

  end
end
