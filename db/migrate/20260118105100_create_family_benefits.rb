class CreateFamilyBenefits < ActiveRecord::Migration[7.2]
  def change
    create_table :family_benefits do |t|
      t.string :verification_status, default: "unverified"
      t.integer :family_members, default: 0
      t.integer :adult_count, default: 0
      t.integer :child_count, default: 0


      t.timestamps
    end
  end
end
