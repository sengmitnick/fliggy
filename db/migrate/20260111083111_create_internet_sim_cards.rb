class CreateInternetSimCards < ActiveRecord::Migration[7.2]
  def change
    create_table :internet_sim_cards do |t|
      t.string :name
      t.string :region
      t.integer :validity_days
      t.string :data_limit
      t.decimal :price
      t.text :features
      t.integer :sales_count, default: 0
      t.string :shop_name


      t.timestamps
    end
  end
end
