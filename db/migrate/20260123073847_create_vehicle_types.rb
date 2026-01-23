class CreateVehicleTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicle_types do |t|
      t.string :name
      t.string :category, default: "5座"
      t.string :level, default: "经济"
      t.integer :seats, default: 5
      t.integer :luggage_capacity, default: 2
      t.decimal :hourly_price_6h
      t.decimal :hourly_price_8h
      t.integer :included_mileage, default: 100
      t.string :image_url


      t.timestamps
    end
  end
end
