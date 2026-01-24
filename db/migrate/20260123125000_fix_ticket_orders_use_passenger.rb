class FixTicketOrdersUsePassenger < ActiveRecord::Migration[7.2]
  def change
    # 删除 traveler_id，添加 passenger_id
    remove_column :ticket_orders, :traveler_id, :integer if column_exists?(:ticket_orders, :traveler_id)
    add_column :ticket_orders, :passenger_id, :integer unless column_exists?(:ticket_orders, :passenger_id)
    
    # 删除 travelers 表（如果存在）
    drop_table :travelers if table_exists?(:travelers)
    
    # 删除 tickets 表的 supplier_id（门票不直接关联供应商，通过 ticket_suppliers 关联）
    remove_column :tickets, :supplier_id, :integer if column_exists?(:tickets, :supplier_id)
  end
end
