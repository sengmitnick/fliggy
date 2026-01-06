class CreateTourItineraryDays < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_itinerary_days do |t|
      t.references :tour_group_product
      t.integer :day_number, default: 1
      t.string :title
      t.text :attractions
      t.text :assembly_point
      t.text :assembly_details
      t.text :disassembly_point
      t.text :disassembly_details
      t.string :transportation
      t.text :service_info
      t.integer :duration_minutes, default: 0


      t.timestamps
    end
  end
end
