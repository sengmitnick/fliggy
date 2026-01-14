class CreateVisaProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :visa_products do |t|
      t.integer :country_id
      t.string :name
      t.string :product_type
      t.decimal :price, default: 0
      t.decimal :original_price
      t.string :residence_area
      t.integer :processing_days
      t.string :visa_validity
      t.string :max_stay
      t.decimal :success_rate, default: 99.9
      t.jsonb :required_materials, default: []
      t.integer :material_count, default: 0
      t.boolean :can_simplify, default: false
      t.boolean :home_pickup, default: false
      t.boolean :refused_reapply, default: false
      t.boolean :supports_family, default: false
      t.jsonb :features, default: []
      t.text :description
      t.string :slug
      t.integer :sales_count, default: 0
      t.string :merchant_name
      t.string :merchant_avatar


      t.timestamps
    end
  end
end
