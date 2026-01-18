class CreateFlightPackages < ActiveRecord::Migration[7.2]
  def change
    create_table :flight_packages do |t|
      t.string :title
      t.string :subtitle
      t.decimal :price, default: 0
      t.decimal :original_price, default: 0
      t.string :discount_label
      t.string :badge_text
      t.string :badge_color, default: "#FF5722"
      t.string :destination
      t.string :image_url
      t.integer :valid_days, default: 365
      t.text :description
      t.text :features
      t.string :status, default: "active"


      t.timestamps
    end
  end
end
