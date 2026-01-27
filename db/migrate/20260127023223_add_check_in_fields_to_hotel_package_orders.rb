class AddCheckInFieldsToHotelPackageOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_package_orders, :check_in_date, :date
    add_column :hotel_package_orders, :check_out_date, :date

  end
end
