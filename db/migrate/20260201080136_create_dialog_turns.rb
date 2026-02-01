class CreateDialogTurns < ActiveRecord::Migration[7.2]
  def change
    create_table :dialog_turns do |t|
      t.references :validator_execution
      t.integer :turn_number
      t.string :role
      t.text :message
      t.jsonb :metadata
      t.string :data_version

      t.timestamps
    end
  end
end
