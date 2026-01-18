class AddIsSelfToPassengers < ActiveRecord::Migration[7.2]
  def change
    add_column :passengers, :is_self, :boolean, default: false, null: false
    add_index :passengers, [:user_id, :is_self]
  end
end
