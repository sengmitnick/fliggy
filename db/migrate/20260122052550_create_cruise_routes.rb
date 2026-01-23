class CreateCruiseRoutes < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_routes do |t|
      t.string :name
      t.string :region
      t.string :icon_url


      t.timestamps
    end
  end
end
