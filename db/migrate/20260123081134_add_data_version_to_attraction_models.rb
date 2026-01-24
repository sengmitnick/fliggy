class AddDataVersionToAttractionModels < ActiveRecord::Migration[7.2]
  def change
    add_column :attractions, :data_version, :integer, default: 0, null: false
    add_column :tickets, :data_version, :integer, default: 0, null: false
    add_column :attraction_activities, :data_version, :integer, default: 0, null: false
    add_column :attraction_reviews, :data_version, :integer, default: 0, null: false
    add_column :ticket_orders, :data_version, :integer, default: 0, null: false
    add_column :activity_orders, :data_version, :integer, default: 0, null: false
  end
end
