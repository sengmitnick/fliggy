class AddVenueToDeepTravelGuides < ActiveRecord::Migration[7.2]
  def change
    add_column :deep_travel_guides, :venue, :string

  end
end
