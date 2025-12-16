class AddAirlineMemberToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :airline_member, :boolean, default: false
  end
end
