class AddContactEmailAndRemarkToCruiseOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :cruise_orders, :contact_email, :string
    add_column :cruise_orders, :remark, :text

  end
end
