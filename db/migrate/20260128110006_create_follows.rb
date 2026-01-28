# frozen_string_literal: true

class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :followable, polymorphic: true, null: false
      t.string :data_version, limit: 50, default: '0', null: false

      t.timestamps
    end

    add_index :follows, [:user_id, :followable_type, :followable_id], unique: true, name: 'index_follows_on_user_and_followable', if_not_exists: true
    add_index :follows, [:followable_type, :followable_id], name: 'index_follows_on_followable', if_not_exists: true
    add_index :follows, :data_version, if_not_exists: true
  end
end
