class CreateNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category
      t.boolean :enabled, default: true


      t.timestamps
    end
    
    add_index :notification_settings, [:user_id, :category], unique: true
  end
end
