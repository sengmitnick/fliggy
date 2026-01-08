class AddStationInfoToBusTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :bus_tickets, :departure_station, :string
    add_column :bus_tickets, :arrival_station, :string
    add_column :bus_tickets, :route_description, :string

  end
end
