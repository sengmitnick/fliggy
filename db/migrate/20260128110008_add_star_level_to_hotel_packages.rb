class AddStarLevelToHotelPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_packages, :star_level, :integer

  end
end
