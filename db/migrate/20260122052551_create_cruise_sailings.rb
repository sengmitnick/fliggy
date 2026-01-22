class CreateCruiseSailings < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_sailings do |t|
      t.references :cruise_ship
      t.references :cruise_route
      t.date :departure_date
      t.date :return_date
      t.integer :duration_days
      t.integer :duration_nights
      t.string :departure_port
      t.string :arrival_port
      t.jsonb :itinerary
      t.string :status, default: "on_sale"


      t.timestamps
    end
  end
end
