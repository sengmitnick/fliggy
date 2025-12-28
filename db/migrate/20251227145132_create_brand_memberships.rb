class CreateBrandMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :brand_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.string :brand_name
      t.string :member_number
      t.string :member_level
      t.string :status, default: "pending"


      t.timestamps
    end
  end
end
