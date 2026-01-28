class CreatePickupLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :pickup_locations do |t|
      t.string :city
      t.string :district
      t.text :detail
      t.string :phone
      t.string :business_hours
      t.text :notes
      t.boolean :is_active, default: true


      t.timestamps
    end
  end
end
