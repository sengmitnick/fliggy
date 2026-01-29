class AddHotelIdToHotelPackageOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_package_orders, :hotel_id, :integer
    add_index :hotel_package_orders, :hotel_id
  end
end
