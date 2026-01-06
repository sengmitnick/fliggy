class AddOrderFieldsToHotelPackageOrders < ActiveRecord::Migration[7.2]
  def change
    add_reference :hotel_package_orders, :package_option, null: false, foreign_key: true
    add_reference :hotel_package_orders, :passenger, null: false, foreign_key: true
    add_column :hotel_package_orders, :booking_type, :string, default: "stockup"
    add_column :hotel_package_orders, :contact_name, :string
    add_column :hotel_package_orders, :contact_phone, :string

  end
end
