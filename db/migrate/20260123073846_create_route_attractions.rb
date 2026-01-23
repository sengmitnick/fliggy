class CreateRouteAttractions < ActiveRecord::Migration[7.2]
  def change
    create_table :route_attractions do |t|
      t.integer :charter_route_id
      t.integer :attraction_id
      t.integer :position, default: 0


      t.timestamps
    end
  end
end
