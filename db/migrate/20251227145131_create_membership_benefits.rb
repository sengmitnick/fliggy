class CreateMembershipBenefits < ActiveRecord::Migration[7.2]
  def change
    create_table :membership_benefits do |t|
      t.string :name
      t.string :level_required, default: "F1"
      t.string :icon
      t.text :description


      t.timestamps
    end
  end
end
