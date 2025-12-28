class CreateItineraries < ActiveRecord::Migration[7.2]
  def change
    create_table :itineraries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.date :start_date
      t.date :end_date
      t.string :destination
      t.string :status, default: "upcoming"


      t.timestamps
    end
    
    add_index :itineraries, [:user_id, :status]
    add_index :itineraries, [:user_id, :start_date]
  end
end
