class CreateAttractions < ActiveRecord::Migration[7.2]
  def change
    create_table :attractions do |t|
      t.string :name
      t.integer :city_id
      t.decimal :latitude
      t.decimal :longitude
      t.text :description
      t.string :cover_image_url


      t.timestamps
    end
  end
end
