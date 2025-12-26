class AddSlugToDestinations < ActiveRecord::Migration[7.2]
  def change
    add_column :destinations, :slug, :string

    add_index :destinations, :slug, unique: true
  end
end
