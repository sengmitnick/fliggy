class CreateInsuranceProductCities < ActiveRecord::Migration[7.2]
  def change
    create_table :insurance_product_cities do |t|
      t.integer :insurance_product_id, null: false
      t.integer :city_id, null: false
      t.decimal :price_per_day, precision: 10, scale: 2
      t.boolean :available, default: true, null: false

      t.timestamps
    end

    add_index :insurance_product_cities, :insurance_product_id
    add_index :insurance_product_cities, :city_id
    add_index :insurance_product_cities, [:insurance_product_id, :city_id], unique: true, name: 'index_insurance_product_cities_on_product_and_city'
    add_index :insurance_product_cities, :available
  end
end
