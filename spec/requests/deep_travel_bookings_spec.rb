require 'rails_helper'

RSpec.describe "Deep travel bookings", type: :request do

  let(:user) { create(:user) }
  let(:guide) { create(:deep_travel_guide) }
  let!(:product) { create(:deep_travel_product, deep_travel_guide: guide) }
  before { sign_in_as(user) }

  describe "GET /deep_travel_bookings/new" do
    it "returns http success" do
      get new_deep_travel_booking_path, params: {
        guide_id: guide.id,
        date: Date.today.to_s,
        adult_count: 2,
        child_count: 1
      }
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
