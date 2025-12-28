class CreateMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.string :level, default: "F1"
      t.integer :points, default: 0
      t.integer :experience, default: 0


      t.timestamps
    end
  end
end
