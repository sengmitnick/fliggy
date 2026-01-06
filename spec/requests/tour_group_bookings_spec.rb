require 'rails_helper'

RSpec.describe "Tour group bookings", type: :request do

  let(:user) { create(:user) }
  let(:product) { TourGroupProduct.includes(:tour_packages).first }
  let(:package) { product.tour_packages.first }
  
  before { sign_in_as(user) }

  describe "GET /tour_group_bookings/new" do
    it "returns http success" do
      skip "Run seeds first" unless product && package
      
      get new_tour_group_booking_path, params: {
        product_id: product.id,
        package_id: package.id,
        travel_date: Date.today.to_s,
        adult_count: 2,
        child_count: 0
      }
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
