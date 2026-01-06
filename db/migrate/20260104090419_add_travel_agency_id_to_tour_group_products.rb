class AddTravelAgencyIdToTourGroupProducts < ActiveRecord::Migration[7.2]
  def change
    add_reference :tour_group_products, :travel_agency, null: false, foreign_key: true

  end
end
