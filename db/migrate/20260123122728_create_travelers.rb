class CreateTravelers < ActiveRecord::Migration[7.2]
  def change
    create_table :travelers do |t|
      t.integer :user_id
      t.string :name
      t.string :id_number
      t.string :phone
      t.string :id_type, default: "id_card"
      t.boolean :is_default, default: false
      t.integer :data_version, default: 0


      t.timestamps
    end
  end
end
