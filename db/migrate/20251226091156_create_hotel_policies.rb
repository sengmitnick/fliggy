class CreateHotelPolicies < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_policies do |t|
      t.references :hotel
      t.string :check_in_time
      t.string :check_out_time
      t.string :pet_policy
      t.string :breakfast_type
      t.string :breakfast_hours
      t.decimal :breakfast_price, default: 0
      t.text :payment_methods


      t.timestamps
    end
  end
end
