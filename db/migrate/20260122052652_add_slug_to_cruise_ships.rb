class AddSlugToCruiseShips < ActiveRecord::Migration[7.2]
  def change
    add_column :cruise_ships, :slug, :string

    add_index :cruise_ships, :slug, unique: true
  end
end
