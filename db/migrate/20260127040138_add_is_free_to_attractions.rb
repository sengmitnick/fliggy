class AddIsFreeToAttractions < ActiveRecord::Migration[7.2]
  def change
    add_column :attractions, :is_free, :boolean

  end
end
