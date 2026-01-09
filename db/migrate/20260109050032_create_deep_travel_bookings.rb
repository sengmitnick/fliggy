class CreateDeepTravelBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :deep_travel_bookings do |t|
      t.references :user
      t.references :deep_travel_guide
      t.references :deep_travel_product
      t.date :travel_date
      t.integer :adult_count, default: 1
      t.integer :child_count, default: 0
      t.string :traveler_name
      t.string :traveler_id_number
      t.string :traveler_phone
      t.string :contact_name
      t.string :contact_phone
      t.decimal :total_price, precision: 10, scale: 2
      t.decimal :insurance_price, precision: 10, scale: 2
      t.string :status, default: 'pending'
      t.string :order_number
      t.text :notes


      t.timestamps
    end
  end
end
