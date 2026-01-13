class CreateAbroadShops < ActiveRecord::Migration[7.2]
  def change
    create_table :abroad_shops do |t|
      t.string :name
      t.integer :abroad_brand_id
      t.string :city
      t.text :address
      t.decimal :latitude
      t.decimal :longitude
      t.string :image_url
      t.text :description


      t.timestamps
    end
  end
end
