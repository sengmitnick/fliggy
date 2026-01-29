# frozen_string_literal: true

class ChangeFollowableIdToString < ActiveRecord::Migration[7.2]
  def up
    # Remove the foreign key constraint if it exists (it shouldn't for polymorphic associations)
    # Change the column type to string
    change_column :follows, :followable_id, :string, null: false
  end

  def down
    # Reverse migration: change back to bigint
    # WARNING: This will lose data if followable_id contains non-numeric strings
    change_column :follows, :followable_id, :bigint, null: false
  end
end
