class CreateCruiseShips < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_ships do |t|
      t.references :cruise_line
      t.string :name
      t.string :name_en
      t.string :image_url
      t.jsonb :features


      t.timestamps
    end
  end
end
