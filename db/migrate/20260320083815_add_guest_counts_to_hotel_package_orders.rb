class AddGuestCountsToHotelPackageOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_package_orders, :room_count, :integer, default: 1
    add_column :hotel_package_orders, :adult_count, :integer, default: 1
    add_column :hotel_package_orders, :child_count, :integer, default: 0

  end
end
