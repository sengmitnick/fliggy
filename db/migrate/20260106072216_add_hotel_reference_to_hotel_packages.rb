class AddHotelReferenceToHotelPackages < ActiveRecord::Migration[7.2]
  def change
    add_reference :hotel_packages, :hotel, null: true, foreign_key: true
    add_column :hotel_packages, :brand, :string
    add_column :hotel_packages, :city, :string
    add_column :hotel_packages, :night_count, :integer, default: 2
    add_column :hotel_packages, :refundable, :boolean, default: false
    add_column :hotel_packages, :instant_booking, :boolean, default: false
    add_column :hotel_packages, :luxury, :boolean, default: false
  end
end
