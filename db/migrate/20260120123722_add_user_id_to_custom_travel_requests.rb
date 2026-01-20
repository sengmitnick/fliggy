class AddUserIdToCustomTravelRequests < ActiveRecord::Migration[7.2]
  def change
    add_reference :custom_travel_requests, :user, null: false, foreign_key: true

  end
end
