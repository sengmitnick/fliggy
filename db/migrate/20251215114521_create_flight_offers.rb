class CreateFlightOffers < ActiveRecord::Migration[7.2]
  def change
    create_table :flight_offers do |t|
      t.references :flight
      t.string :provider_name
      t.string :offer_type, default: "standard"
      t.decimal :price
      t.decimal :original_price
      t.decimal :cashback_amount, default: 0
      t.text :discount_items
      t.string :seat_class, default: "economy"
      t.text :services
      t.text :tags
      t.string :baggage_info
      t.boolean :meal_included, default: false
      t.string :refund_policy
      t.boolean :is_featured, default: false
      t.integer :display_order, default: 0


      t.timestamps
    end
  end
end
