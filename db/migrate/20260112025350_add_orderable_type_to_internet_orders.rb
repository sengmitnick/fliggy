class AddOrderableTypeToInternetOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :internet_orders, :orderable_type, :string
    add_index :internet_orders, [:orderable_type, :orderable_id]
  end
end
