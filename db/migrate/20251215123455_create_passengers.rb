class CreatePassengers < ActiveRecord::Migration[7.2]
  def change
    create_table :passengers do |t|
      t.string :name
      t.string :id_type, default: "身份证"
      t.string :id_number
      t.string :phone


      t.timestamps
    end
  end
end
