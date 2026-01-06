class CreateCars < ActiveRecord::Migration[7.2]
  def change
    create_table :cars do |t|
      t.string :brand
      t.string :car_model
      t.string :category, default: "经济轿车"
      t.integer :seats, default: 5
      t.integer :doors, default: 4
      t.string :transmission, default: "自动挡"
      t.string :fuel_type
      t.string :engine
      t.decimal :price_per_day, default: 0
      t.decimal :total_price, default: 0
      t.decimal :discount_amount, default: 0
      t.string :location, default: "武汉"
      t.string :pickup_location
      t.text :features
      t.text :tags
      t.boolean :is_featured, default: false
      t.boolean :is_available, default: true
      t.integer :sales_rank, default: 0


      t.timestamps
    end
  end
end
