class CreateVisaServices < ActiveRecord::Migration[7.2]
  def change
    create_table :visa_services do |t|
      t.string :title
      t.string :country
      t.string :service_type, default: "全国送签"
      t.decimal :success_rate, default: 100.0
      t.integer :processing_days, default: 5
      t.integer :price, default: 0
      t.integer :original_price
      t.boolean :urgent_processing, default: false
      t.text :description
      t.string :merchant_name
      t.integer :sales_count, default: 0
      t.string :slug
      t.string :image_url

      t.index :slug, unique: true

      t.timestamps
    end
  end
end
