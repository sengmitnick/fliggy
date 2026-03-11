class AddValidatorIdFieldsToValidatorExecutions < ActiveRecord::Migration[7.2]
  def change
    add_column :validator_executions, :validator_id, :string
    add_column :validator_executions, :score, :integer
    add_column :validator_executions, :status, :string
    add_column :validator_executions, :verify_result, :jsonb
    
    add_index :validator_executions, :validator_id
    add_index :validator_executions, [:validator_id, :created_at]
  end
end
