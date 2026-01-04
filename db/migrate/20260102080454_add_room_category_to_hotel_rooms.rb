class AddRoomCategoryToHotelRooms < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_rooms, :room_category, :string, default: 'overnight'
    add_index :hotel_rooms, :room_category
  end
end
