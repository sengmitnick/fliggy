class AddCascadeDeleteToBusTicketPassengers < ActiveRecord::Migration[7.2]
  def up
    # 删除现有外键约束
    remove_foreign_key :bus_ticket_passengers, :bus_ticket_orders
    
    # 添加带 ON DELETE CASCADE 的外键约束
    add_foreign_key :bus_ticket_passengers, :bus_ticket_orders, on_delete: :cascade
  end
  
  def down
    # 回滚时恢复原来的外键约束（不带 CASCADE）
    remove_foreign_key :bus_ticket_passengers, :bus_ticket_orders
    add_foreign_key :bus_ticket_passengers, :bus_ticket_orders
  end
end
