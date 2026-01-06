class CreateCarOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :car_orders do |t|
      t.belongs_to :user
      t.belongs_to :car
      t.string :driver_name
      t.string :driver_id_number
      t.string :contact_phone
      t.datetime :pickup_datetime
      t.datetime :return_datetime
      t.string :pickup_location
      t.string :status, default: "pending"
      t.decimal :total_price, default: 0


      t.timestamps
    end
  end
end
