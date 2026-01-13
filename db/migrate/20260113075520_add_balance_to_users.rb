class AddBalanceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :balance, :decimal, precision: 10, scale: 2, default: 0.0, null: false

  end
end
