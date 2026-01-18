class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.boolean :is_default, default: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
