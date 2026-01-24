class AddAttractionToTourGroupProducts < ActiveRecord::Migration[7.2]
  def change
    add_reference :tour_group_products, :attraction, null: true, foreign_key: true

  end
end
