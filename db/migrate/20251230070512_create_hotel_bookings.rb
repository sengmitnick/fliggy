class CreateHotelBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :hotel_bookings do |t|
      t.references :hotel
      t.references :user
      t.references :hotel_room
      t.date :check_in_date
      t.date :check_out_date
      t.integer :rooms_count, default: 1
      t.integer :adults_count, default: 1
      t.integer :children_count, default: 0
      t.string :guest_name
      t.string :guest_phone
      t.decimal :total_price
      t.decimal :original_price
      t.decimal :discount_amount, default: 0.0
      t.string :payment_method, default: "在线付"
      t.string :coupon_code
      t.text :special_requests
      t.string :status, default: "pending"


      t.timestamps
    end
  end
end
