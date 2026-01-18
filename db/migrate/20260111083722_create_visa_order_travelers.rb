class CreateVisaOrderTravelers < ActiveRecord::Migration[7.2]
  def change
    create_table :visa_order_travelers do |t|
      t.integer :visa_order_id
      t.string :name
      t.string :id_number
      t.string :phone
      t.string :relationship
      t.string :passport_number
      t.date :passport_expiry


      t.timestamps
    end
  end
end
