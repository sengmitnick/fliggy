class CreateTrains < ActiveRecord::Migration[7.2]
  def change
    create_table :trains do |t|
      t.string :departure_city
      t.string :arrival_city
      t.datetime :departure_time
      t.datetime :arrival_time
      t.integer :duration
      t.string :train_number
      t.text :seat_types
      t.decimal :price_second_class
      t.decimal :price_first_class
      t.decimal :price_business_class
      t.integer :available_seats


      t.timestamps
    end
  end
end
