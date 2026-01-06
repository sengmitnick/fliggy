class AddSlugToHotelPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_packages, :slug, :string

    add_index :hotel_packages, :slug, unique: true
  end
end
