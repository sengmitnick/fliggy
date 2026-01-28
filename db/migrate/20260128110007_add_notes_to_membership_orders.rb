class AddNotesToMembershipOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :membership_orders, :notes, :text

  end
end
