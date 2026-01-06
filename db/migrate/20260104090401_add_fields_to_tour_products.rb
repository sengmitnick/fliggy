class AddFieldsToTourProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :tour_products, :tour_type, :string
    add_column :tour_products, :duration, :integer
    add_column :tour_products, :departure_city, :string
    add_column :tour_products, :rating_desc, :string
    add_column :tour_products, :highlights, :text
    add_column :tour_products, :provider, :string
    add_column :tour_products, :badge, :string
    add_column :tour_products, :departure_label, :string
    add_column :tour_products, :price_suffix, :string, default: "起"

  end
end
