class AddSlugToCruiseLines < ActiveRecord::Migration[7.2]
  def change
    add_column :cruise_lines, :slug, :string

    add_index :cruise_lines, :slug, unique: true
  end
end
