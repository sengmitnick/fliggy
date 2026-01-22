class CreateInsuranceProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :insurance_products do |t|
      t.string :name, null: false
      t.string :company, null: false
      t.string :product_type, null: false
      t.string :code, null: false
      
      # 保障详情
      t.jsonb :coverage_details, default: {}
      t.decimal :price_per_day, precision: 10, scale: 2
      t.integer :min_days, default: 1
      t.integer :max_days, default: 365
      
      # 标签和亮点
      t.string :scenes, array: true, default: []
      t.string :highlights, array: true, default: []
      t.boolean :official_select, default: false
      t.boolean :featured, default: false
      
      # 内嵌保险关联
      t.boolean :available_for_embedding, default: false
      t.string :embedding_code
      
      t.string :image_url
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      
      t.timestamps
    end
    
    add_index :insurance_products, :code, unique: true
    add_index :insurance_products, :product_type
    add_index :insurance_products, :company
    add_index :insurance_products, :embedding_code
    add_index :insurance_products, [:active, :sort_order]
  end
end
