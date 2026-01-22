class CreateCruiseLines < ActiveRecord::Migration[7.2]
  def change
    create_table :cruise_lines do |t|
      t.string :name
      t.string :name_en
      t.string :logo_url
      t.text :description


      t.timestamps
    end
  end
end
