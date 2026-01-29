class CreateDeepTravelReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :deep_travel_reviews do |t|
      t.references :deep_travel_guide
      t.references :user
      t.decimal :rating, default: 5.0
      t.text :content
      t.integer :helpful_count, default: 0
      t.date :visit_date
      t.string :data_version, default: "'0'"


      t.timestamps
    end
  end
end
