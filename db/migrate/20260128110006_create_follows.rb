class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      t.references :user
      t.string :followable_type
      t.string :followable_id
      t.string :data_version, limit: 50, default: '0', null: false

      t.timestamps
    end
    
    add_index :follows, [:user_id, :followable_type, :followable_id], unique: true, name: 'index_follows_on_user_and_followable'
    add_index :follows, [:followable_type, :followable_id], name: 'index_follows_on_followable'
    add_index :follows, :data_version
  end
end
