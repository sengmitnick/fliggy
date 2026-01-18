class AddIsActiveToValidatorExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :validator_executions, :is_active, :boolean, default: false
    add_column :validator_executions, :user_id, :bigint

    # 添加索引以优化活跃会话查询
    add_index :validator_executions, [:user_id, :is_active]
    add_index :validator_executions, :is_active
  end
end
