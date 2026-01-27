class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.string :followable_type, null: false
      t.string :followable_id, null: false

      t.timestamps
    end
    
    add_index :follows, [:user_id, :followable_type, :followable_id], unique: true, name: 'index_follows_on_user_and_followable'
  end
end
