class CreateTravelAgencies < ActiveRecord::Migration[7.2]
  def change
    create_table :travel_agencies do |t|
      t.string :name
      t.text :description
      t.string :logo_url
      t.decimal :rating, default: 5.0
      t.integer :sales_count, default: 0
      t.boolean :is_verified, default: false


      t.timestamps
    end
  end
end
