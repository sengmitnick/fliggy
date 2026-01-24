class CreateCharterRoutes < ActiveRecord::Migration[7.2]
  def change
    create_table :charter_routes do |t|
      t.string :name
      t.integer :city_id
      t.string :slug
      t.integer :duration_days, default: 1
      t.integer :distance_km, default: 100
      t.string :category, default: "featured"
      t.text :description
      t.decimal :price_from
      t.text :highlights
      t.string :cover_image_url


      t.timestamps
    end
  end
end
