class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category
      t.string :title
      t.text :content
      t.boolean :read, default: false
      t.integer :badge_count, default: 0


      t.timestamps
    end
    
    add_index :notifications, [:user_id, :category]
    add_index :notifications, [:user_id, :read]
  end
end
