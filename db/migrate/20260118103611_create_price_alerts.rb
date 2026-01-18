class CreatePriceAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :price_alerts do |t|
      t.string :departure
      t.string :destination
      t.decimal :expected_price
      t.date :departure_date
      t.string :status, default: "active"


      t.timestamps
    end
  end
end
