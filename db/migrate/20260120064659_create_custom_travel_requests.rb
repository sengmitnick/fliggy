class CreateCustomTravelRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_travel_requests do |t|
      t.string :departure_city
      t.string :destination_city
      t.integer :adults_count, default: 2
      t.integer :children_count, default: 0
      t.integer :elders_count, default: 0
      t.date :departure_date
      t.integer :days_count, default: 1
      t.text :preferences
      t.string :phone
      t.integer :expected_merchants, default: 1
      t.string :contact_time
      t.string :status, default: "pending"


      t.timestamps
    end
  end
end
