class CreateItineraryItems < ActiveRecord::Migration[7.2]
  def change
    create_table :itinerary_items do |t|
      t.references :itinerary, null: false, foreign_key: true
      t.string :item_type
      t.string :bookable_type
      t.integer :bookable_id
      t.date :item_date
      t.integer :sequence, default: 0

      t.timestamps
    end
    
    add_index :itinerary_items, [:itinerary_id, :sequence]
    add_index :itinerary_items, [:bookable_type, :bookable_id]
  end
end
