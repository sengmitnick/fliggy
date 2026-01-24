class CreateAttractions < ActiveRecord::Migration[7.2]
  def change
    create_table :attractions do |t|
      t.string :name
      t.string :province
      t.string :city
      t.string :district
      t.text :address
      t.decimal :latitude
      t.decimal :longitude
      t.decimal :rating, default: 0
      t.integer :review_count, default: 0
      t.string :opening_hours
      t.string :phone
      t.text :description
      t.string :slug


      t.timestamps
    end
  end
end
