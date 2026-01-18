class CreateValidatorExecutions < ActiveRecord::Migration[7.2]
  def change
    create_table :validator_executions do |t|
      t.string :execution_id
      t.jsonb :state

      t.timestamps
    end

    add_index :validator_executions, :execution_id, unique: true
  end
end
