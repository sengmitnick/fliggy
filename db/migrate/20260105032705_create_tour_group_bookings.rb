class CreateTourGroupBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_group_bookings do |t|
      t.integer :tour_group_product_id
      t.integer :tour_package_id
      t.integer :user_id
      t.date :travel_date
      t.integer :adult_count, default: 1
      t.integer :child_count, default: 0
      t.string :contact_name
      t.string :contact_phone
      t.string :insurance_type, default: "none"
      t.string :status, default: "pending"
      t.decimal :total_price

      t.index :tour_group_product_id
      t.index :tour_package_id
      t.index :user_id

      t.timestamps
    end
  end
end
