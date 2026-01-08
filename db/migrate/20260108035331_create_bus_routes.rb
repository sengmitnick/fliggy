class CreateBusRoutes < ActiveRecord::Migration[7.2]
  def change
    create_table :bus_routes do |t|
      t.string :origin
      t.string :destination
      t.integer :duration


      t.timestamps
    end
  end
end
