class CreateSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.string :supplier_type, default: "official"
      t.decimal :rating
      t.integer :sales_count, default: 0
      t.text :description
      t.string :contact_phone
      t.integer :data_version, default: 0


      t.timestamps
    end
  end
end
