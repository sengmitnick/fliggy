class AddThemesToCities < ActiveRecord::Migration[7.2]
  def change
    add_column :cities, :themes, :text

  end
end
