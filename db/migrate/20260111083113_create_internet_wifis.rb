class CreateInternetWifis < ActiveRecord::Migration[7.2]
  def change
    create_table :internet_wifis do |t|
      t.string :name
      t.string :region
      t.string :network_type
      t.string :data_limit
      t.decimal :daily_price
      t.text :features
      t.integer :sales_count, default: 0
      t.string :shop_name
      t.decimal :deposit, default: 0


      t.timestamps
    end
  end
end
