class CreateHotelRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_rooms do |t|
      t.integer :hotel_id
      t.string :room_type, default: "标准间"
      t.string :bed_type
      t.decimal :price
      t.decimal :original_price
      t.string :area
      t.integer :max_guests, default: 2
      t.boolean :has_window, default: true
      t.integer :available_rooms, default: 10


      t.timestamps
    end
  end
end
