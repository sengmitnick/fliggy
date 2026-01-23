class AddSpecialRequirementsToCharterBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :charter_bookings, :special_requirements, :text

  end
end
