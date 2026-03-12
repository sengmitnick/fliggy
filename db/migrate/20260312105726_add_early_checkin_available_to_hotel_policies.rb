class AddEarlyCheckinAvailableToHotelPolicies < ActiveRecord::Migration[7.2]
  def change
    add_column :hotel_policies, :early_checkin_available, :boolean, default: false, null: false
  end
end
