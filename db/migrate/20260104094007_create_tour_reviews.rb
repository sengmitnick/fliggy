class CreateTourReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :tour_reviews do |t|
      t.references :tour_group_product
      t.references :user
      t.decimal :rating, default: 5.0
      t.decimal :guide_attitude, default: 5.0
      t.decimal :meal_quality, default: 5.0
      t.decimal :itinerary_arrangement, default: 5.0
      t.decimal :travel_transportation, default: 5.0
      t.text :comment
      t.boolean :is_featured, default: false
      t.integer :helpful_count, default: 0


      t.timestamps
    end
  end
end
