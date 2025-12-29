class CreateDeepTravelGuides < ActiveRecord::Migration[7.2]
  def change
    create_table :deep_travel_guides do |t|
      t.string :name
      t.string :title
      t.text :description
      t.integer :follower_count, default: 0
      t.integer :experience_years, default: 0
      t.text :specialties
      t.decimal :price, precision: 10, scale: 2
      t.integer :served_count, default: 0
      t.integer :rank
      t.decimal :rating, precision: 3, scale: 2
      t.boolean :featured, default: false


      t.timestamps
    end
  end
end
