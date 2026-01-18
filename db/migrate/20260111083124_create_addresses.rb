class CreateAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses do |t|
      t.references :user
      t.string :name
      t.string :phone
      t.string :province
      t.string :city
      t.string :district
      t.string :detail
      t.boolean :is_default, default: false
      t.string :address_type, default: "delivery"


      t.timestamps
    end
  end
end
