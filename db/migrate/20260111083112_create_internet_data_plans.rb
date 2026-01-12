class CreateInternetDataPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :internet_data_plans do |t|
      t.string :name
      t.string :region
      t.integer :validity_days
      t.string :data_limit
      t.decimal :price
      t.string :phone_number
      t.string :carrier
      t.text :description


      t.timestamps
    end
  end
end
