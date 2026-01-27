class AddStockToAttractionActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :attraction_activities, :stock, :integer

  end
end
