class AddNotesToActivityOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :activity_orders, :notes, :text

  end
end
